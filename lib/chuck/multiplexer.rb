require 'uri'
require 'yajl'
require 'haml'
require 'cuuid/uuid'
require 'http-parser'
require 'chuck/profile'

module Chuck
  class Headers
    include Enumerable

    def initialize
      @content = []
    end

    def << value
      @content << value
    end

    def to_s
      Yajl.dump(Hash[*@content])
    end

    def each &block
      @content.each_slice(2, &block)
    end
  end

  module Multiplexer
    attr_reader :options, :profile

    METHOD_URI_RE  = %r{\A(?<method>[[:upper:]]+)\s(?<uri>http://[^\s]+)}i
    METHOD_PATH_RE = %r{\A(?<method>[[:upper:]]+)\s(?<uri>/[^\s]*)}i

    def initialize options = {}
      @buffer  = ''
      @pending = 0
      @options = options
      @channel = options.fetch(:channel)
      @profile = Profile.new(options.fetch(:profile))

      @parser  = HTTP::Parser.new
      @session = Session.create
      @request = Request.new(session_id: @session.id, body: '', headers: Headers.new)

      %w(on_message_complete on_url on_header_field on_header_value on_body).each do |name|
        @parser.send(name, &method(name.to_sym))
      end
    end

    def on_url url
      @request.uri = parse_url(url) unless @request.uri
    end

    def on_header_field value
      @request.headers << value
    end

    def on_header_value value
      @request.headers << value
    end

    def on_body data
      @request.body << data
    end

    def on_message_complete
      @request.body   = @request.body.force_encoding(Encoding::UTF_8)
      @request.method = @parser.http_method
      Request.create(@request) unless @request.id
      intercept
    end

    def intercept
      @parser.reset
      if @request.connect?
        http_connect
      else
        @pending += 1
        forward_to_server
      end
      @buffer = ''
    end

    def ssl_config
      options[:ssl_config].merge(verify_peer: false)
    end

    # data from client
    def receive_data data
      @buffer << data
      @parser << data
    rescue => e
      Chuck.log_error(e)
      http_error(400, 'Invalid Headers', e)
    end

    def parse_url url
      case url
        when %r{^[^/]+:\d+$}
          uri_generic(*url.split(/:/))
        else %r{^https?://}i
          URI.parse(url)
      end
    end

    def uri_generic host, port
      URI.parse("").tap do |uri|
        uri.host, uri.port = host, port.to_i
      end
    end

    def start_ssl
      start_tls(ssl_config)
    end

    def http_connect
      establish_backend_connection(@request.uri.host, @request.uri.port)
      http_response(200, "Connected")
      start_ssl if @request.ssl?
      @buffer = ''
    end

    def forward_to_client data
      @pending -= 1
      send_data(data)
      close_connection(true)
    end

    def finish
      @channel.push(request_html) unless @request.connect?
      http_error(504, 'Gateway timeout') if @pending > 0
    end

    def request_html
      haml = Haml::Engine.new(File.read(Chuck.root + 'views/request/_request.haml'))
      haml.render(self, request: @request)
    end

    def url *path
      params = path[-1].respond_to?(:to_hash) ? path.delete_at(-1).to_hash : {}
      params = params.empty? ? '' : '?' + URI.escape(params.map{|*a| a.join('=')}.join('&')).to_s
      ['/', path.compact.map(&:to_s)].flatten.join('/').gsub(%r{/+}, '/') + params
    end

    def forward_to_server
      profile.process!(@buffer)
      method, uri = parse_rewritten_header

      if @backend or @request.uri != uri
        @request.update(uri: absolute_uri(uri), rewritten: true, method: method)
      end

      establish_backend_connection(uri.host, uri.port) unless @backend

      # NOTE: some web servers do not like full URI in request. e.g. thin.
      # @buffer.sub!(%r{\A(?<method>\w+\s)(?:https?://[^/]+/?)}i) {$~[:method] + '/'}
      @backend.send_data(@buffer)
    rescue => e
      Chuck.log_error(e)
      http_error(400, 'Bad chuck Header', e)
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
        @request.update(uri: uri_generic(host, port), rewritten: true)
      end

      @backend = EM.connect(host, port, Backend, host: host, port: port, plexer: self, request: @request)
    end

    def unbind
      @backend && @backend.close_connection(true)
      @backend = nil
    end

    def parse_rewritten_header
      match = @buffer.match(METHOD_URI_RE) || @buffer.match(METHOD_PATH_RE)
      match or raise 'Invalid URI'
      [match[:method], URI.parse(match[:uri])]
    end

    def http_error code, message, e = nil
      http_response(code, message)
      close_connection(true)
    end

    def http_response code, message
      send_data("HTTP/1.1 #{code} #{message}\r\n\r\n")
    end
  end # Multiplexer
end # Chuck
