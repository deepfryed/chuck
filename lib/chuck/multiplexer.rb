require 'uri'
require 'yajl'
require 'cuuid/uuid'
require 'http-parser'
require 'chuck/profile'
require 'chuck/render'
require 'chuck/ssl'

module Chuck
  module Multiplexer
    attr_reader :options, :profile

    METHOD_URI_RE  = %r{\A(?<method>[[:upper:]]+)\s(?<uri>http://[^\s]+)}i
    METHOD_PATH_RE = %r{\A(?<method>[[:upper:]]+)\s(?<uri>/[^\s]*)}i

    def self.listen host, port, options = {}
      EM.start_server(host, port, self, options)
    end

    def initialize options = {}
      @pending = 0
      @options = options
      @channel = options.fetch(:channel)
      @profile = Profile.new(options.fetch(:profile))
      @parser  = HTTP::Parser.new(HTTP::Parser::TYPE_REQUEST)

      @session = Session.create
      @request = Request.new(session_id: @session.id, body: '', headers: Headers.new)

      %w(on_message_complete on_url on_header_field on_header_value on_headers_complete on_body).each do |name|
        @parser.send(name, &method(name.to_sym))
      end
    end

    # Data from client
    def receive_data data
      @parser << data
    rescue => e
      Chuck.log_error(e)
      http_error(400, 'Invalid Headers')
    end

    def on_url url
      @request.uri = parse_url(@request.uri, url)
    end

    def on_header_field value
      @request.headers.stream(:f, value)
    end

    def on_header_value value
      @request.headers.stream(:v, value)
    end

    def on_headers_complete
      @request.version = @parser.http_version
      @request.headers.stream_complete
    end

    def on_body data
      @request.body << data
    end

    def on_message_complete
      @request.body   = @request.body.force_encoding(Encoding::UTF_8)
      @request.method = @parser.http_method
      @request.save
      intercept
    end

    def intercept
      @parser.reset
      response = catch(:halt) { pre_process }

      if Response === response
        request_callback
        forward_to_client(response)
      elsif @request.connect?
        http_connect
      else
        @pending += 1
        forward_to_server
      end
    end

    def pre_process
      profile.process!(@request)
      @request.save
    rescue => e
      Chuck.log_error(e)
      http_error(502, 'Proxy Filter Error', e.message)
    end

    def parse_url base, url
      case url
        when %r{^(?<host>[^/:]+):(?<port>\d+)$}
          URI.parse("%s://#{$~[:host]}" % ($~[:port].to_i == 443 ? "https" : "http"))
        when %r{^https?://}i
          URI.parse(url)
        else
          base + url
      end
    end

    def https_uri host, port
      URI.parse("https://#{host}:#{port}/")
    end

    def http_connect
      establish_backend_connection(@request.uri.host, @request.uri.port)
    end

    def start_ssl certificate
      http_response(200, "Connected")
      if @request.ssl?
        @ssl = SSL.certificate(subject_for(certificate))
        start_tls(cert_chain_file: @ssl.certificate_file, private_key_file: @ssl.private_key_file, verify_peer: false)
      end
    end

    def subject_for certificate
      subject = OpenSSL::X509::Certificate.new(certificate).subject.to_a
      subject = subject.to_a.map {|value| value.take(2)}.reject {|f, v| f == 'CN'}
      subject << ['CN', @request.uri.host]
      OpenSSL::X509::Name.new(subject)
    end

    def response_callback response
      if callback = profile.callbacks[:response][@request.uri.host] || profile.callbacks[:response][nil]
        begin
          callback.call(response)
        rescue => e
          Chuck.log_error(e)
          http_error(504, 'Gateway timeout')
        end
      end
    end

    def forward_to_server
      unless @request.uri.host
        http_error(400, 'Bad Request', 'No Host Specificed')
        return
      end

      establish_backend_connection(@request.uri.host, @request.uri.port) unless @backend

      request_callback
      @backend.send_data(@request.to_s)
    rescue => e
      Chuck.log_error(e)
      http_error(400, 'Bad Request', 'Error parsing request')
    end

    def forward_to_client response
      response_callback(response)
      response.save
      @pending -= 1
      send_data(response.to_s)
      close_connection(true)
    end

    def finish
      if @channel && !@request.connect?
        @channel.push Render.haml('request/_request.haml', request: @request)
      end
      if @pending > 0
        http_error(504, 'Gateway timeout', 'Backend closed connection')
      end
    end

    def request_callback
      @r_callback_done = true
      if callback = profile.callbacks[:request][@request.uri.host] || profile.callbacks[:request][nil]
        begin
          callback.call(@request)
        rescue => e
          Chuck.log_error(e)
          http_error(504, 'Gateway Timeout', 'Backend closed connection or timed out')
        end
      end
    end

    def absolute_uri uri
      case uri
        when URI::HTTP, URI::HTTPS
          uri
        else
          URI.parse("https://#{@request.uri.host}#{uri}")
      end
    end

    def establish_backend_connection host, port
      return if @backend

      if scope = profile.scopes[profile.scope_key(host, port)]
        @profile = scope
        host     = profile.host
        port     = profile.port
      end

      if port == 443 && @request.uri.host != host
        @request.update(uri: https_uri(host, port), rewritten: true)
      end

      @backend = EM.connect(host, port, Backend, host: host, port: port, plexer: self, request: @request)
    end

    def unbind
      @backend && @backend.close_connection(true)
      @backend = nil
    end

    def http_error code, status, message = ''
      response = @request.response || Response.create(request_id: @request.id, session_id: @session.id)
      response.update(status: code, body: message)

      request_callback unless @r_callback_done
      response_callback(response)

      http_response(code, status, message)
      close_connection(true)
    end

    def http_response code, status, message = ''
      send_data("HTTP/1.1 #{code} #{status}\r\n")
      send_data("Content-Length: #{message.bytesize}\r\n\r\n")
      send_data(message)
    end
  end # Multiplexer
end # Chuck
