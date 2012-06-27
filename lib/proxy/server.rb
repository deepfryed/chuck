require 'pathname'
require 'eventmachine'
require 'proxy/session'
require 'proxy/request'
require 'proxy/response'
require 'proxy/multiplexer'
require 'proxy/backend'

module Proxy
  class Server
    attr_reader :host, :port
    def initialize options = {}
      @host     = options.fetch(:host,   '0.0.0.0')
      @port     = options.fetch(:port,    8080)
      @profile  = options.fetch(:profile, Dir[Proxy.root + 'profiles/sample.rb'])
      @ssl      = Proxy.ssl_config
    end

    def stop *args
      puts $/, "Proxy::Server - shutting down"
      EM.stop
    end

    def start
      %w(INT HUP TERM).each {|name| Signal.trap(name,  &method(:stop))}

      EM.run do
        EM.start_server(host, port, Multiplexer, ssl_config: @ssl, profile: @profile)
        puts "Proxy::Server - listening on #{host}:#{port}"
      end
    end
  end # Server
end # Proxy
