require 'uri'
require 'cuuid/uuid'
require 'http-parser'
require 'proxy/profile'

module Proxy
  module Multiplexer
    attr_reader :options, :profile

    def initialize options = {}
      @buffer  = ''
      @pending = 0
      @options = options
      @profile = Profile.new(options.fetch(:profile))

      @parser  = HTTP::Parser.new
      @parser.on_message_complete(&method(:on_message))
      @parser.on_url(&method(:on_url))
    end

    def ssl_config
      options[:ssl_config].merge(verify_peer: false)
    end

    # data from client
    def receive_data data
      @buffer << data
      @parser << data
    rescue => e
      http_error(400, 'Invalid Headers', e)
    end

    def on_url url
      case url
        when %r{^[^/]+:\d+$}
          @uri = uri_generic(*url.split(/:/))
        else %r{^https?://}i
          @uri = URI.parse(url)
      end
    end

    def uri_generic host, port
      URI.parse("").tap do |uri|
        uri.host, uri.port = host, port.to_i
      end
    end

    def on_message
      if @parser.http_method == 'CONNECT'
        http_connect
      else
        @pending += 1
        forward_to_server
        @buffer = ''
      end
      @parser.reset
    end

    def http_error code, message, e = nil
      http_response(code, message)
      close_connection(true)
      Proxy.log_error(e, session) if e
    end

    def http_response code, message
      send_data("HTTP/1.1 #{code} #{message}\r\n\r\n")
    end

    def start_ssl
      start_tls(ssl_config)
    end

    def http_connect
      ssl = @uri.port == 443
      Proxy.log "#{session}, CONNECT, #{@uri.host}:#{@uri.port}"
      establish_backend_connection(@uri.host, @uri.port)
      http_response(200, "Connected")
      start_ssl if ssl
      @buffer = ''
    end

    # TODO proxy keep-alive
    def forward_to_client data
      @pending -= 1
      send_data(data)
      close_connection(true)
    end

    def finish
      http_error(504, 'Gateway timeout') if @pending > 0
    end

    def forward_to_server
      Proxy.log "#{session}, #{@parser.http_method}, #{@uri}"

      profile.process!(@buffer)
      method, uri = parse_rewritten_header
      Proxy.log "#{session}, #{method}, #{uri}"

      establish_backend_connection(uri.host, uri.port) unless @backend
      @backend.send_data(@buffer)
    rescue => e
      http_error(400, 'Bad proxy Header', e)
    end

    def start_session
      @session ||= UUID.generate
    end

    alias_method :session, :start_session

    def establish_backend_connection host, port
      return if @backend

      start_session
      if scope = profile.scopes[profile.scope_key(host, port)]
        @profile = scope
        host     = profile.host
        port     = profile.port
      end

      if port == 443
        Proxy.log "#{session}, CONNECT, #{host}:#{port}"
      end

      @backend = EM.connect(host, port, Backend, host: host, port: port, plexer: self, ssl: port == 443, session: session)
    end

    def unbind
      @backend && @backend.close_connection(true)
      @backend = nil
    end

    METHOD_URI_RE  = %r{\A(?<method>[[:upper:]]+)\s(?<uri>http://[^\s]+)}i
    METHOD_PATH_RE = %r{\A(?<method>[[:upper:]]+)\s(?<uri>/[^\s]+)}i

    def parse_rewritten_header
      match = @buffer.match(METHOD_URI_RE) || @buffer.match(METHOD_PATH_RE)
      match or raise 'Invalid URI'
      [match[:method], URI.parse(match[:uri])]
    end
  end # Multiplexer
end # Proxy
