require 'uri'
require 'logger'
require 'http/parser'
require 'proxy/profile'

module Proxy
  module Multiplexer
    attr_reader :options, :profile, :logger

    def initialize options = {}
      @buffer  = ''
      @pending = 0
      @options = options
      @parser  = Http::Parser.new
      @profile = Profile.new(options.fetch(:profile))
      @logger  = Logger.new(options.fetch(:logger, $stderr), 0)
      @parser.on_message_complete = method(:on_message)
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

    def on_message
      case http_method
        when nil
          http_error(400, 'Invalid HTTP method')
        when 'CONNECT'
          http_connect
        else
          @pending += 1
          forward_to_server(@buffer)
          @buffer = ''
      end
      #@parser.reset!
    end

    def http_method
      @buffer.scan(%r{\A([[:upper:]]+)\s}).flatten.first
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
      profile.process! @buffer
      if match = @buffer.match(%r{\ACONNECT (?<host>[^:]+)(?::(?<port>\d+))?})
        host, port = match[:host], (match[:port] || 443).to_i
        @buffer    = ''
        ssl        = port == 443

        establish_backend_connection(host, port, Backend, self, ssl)
        http_response(200, "Connected")
        start_ssl if ssl
      else
        http_error(400, "Invalid CONNECT host/port")
      end
    end

    def forward_to_client data
      @pending -= 1
      send_data(data)
    end

    def finish
      http_error(504, 'Gateway timeout') if @pending > 0
    end

    def forward_to_server data
      profile.process! data
      unless @backend
        establish_backend_connection(*endpoint, Backend, self, false)
      end
      @backend.send_data(data)
    rescue => e
      http_error(400, 'Bad proxy Header', e)
    end

    def establish_backend_connection host, port, *args
      return if @backend
      if scope = profile.scopes[profile.scope_key(host, port)]
        @profile = scope
        host = profile.host
        port = profile.port
      end
      @backend = EM.connect(host, port, *args)
    end

    def unbind
      @backend && @backend.close_connection(true)
      @backend = nil
    end

    def endpoint
      match = @buffer.match(%r{\A[[:upper:]]+\s(?<uri>http://[^\s]+)}) or raise 'Invalid URI'
      uri   = URI.parse(match[:uri])
      [uri.host, uri.port]
    end
  end # Multiplexer
end # Proxy
