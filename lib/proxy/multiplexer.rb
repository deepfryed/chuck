require 'uri'
require 'cuuid/uuid'
require 'logger'
require 'http-parser'
require 'proxy/profile'

module Proxy
  module Multiplexer
    attr_reader :options, :profile, :logger

    def initialize options = {}
      @buffer  = ''
      @pending = 0
      @options = options
      @profile = Profile.new(options.fetch(:profile))
      @logger  = Logger.new(options.fetch(:logger, $stderr), 0)

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
      @uri = URI.parse(url)
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
      if e
        logger.error(e)
        logger.error(e.backtrace.take(20).join($/))
      end
    end

    def http_response code, message
      send_data("HTTP/1.1 #{code} #{message}\r\n\r\n")
    end

    def start_ssl
      start_tls(ssl_config)
    end

    def http_connect
      host, port = @uri.to_s.split(/:/)
      ssl        = port.to_i == 443
      Proxy.log "#{session}, CONNECT, #{host}:#{port}"
      establish_backend_connection(host, port.to_i)
      http_response(200, "Connected")
      start_ssl if ssl
      @buffer = ''
    end

    def forward_to_client data
      @pending -= 1
      send_data(data)
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

    def session
      @session ||= UUID.generate
    end

    def establish_backend_connection host, port
      return if @backend

      session
      if scope = profile.scopes[profile.scope_key(host, port)]
        @profile = scope
        host     = profile.host
        port     = profile.port
      end
      Proxy.log "#{session}, CONNECT, #{host}:#{port}"
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
