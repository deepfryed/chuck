require 'pathname'
require 'eventmachine'
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

    def start
      EM.run do
        EM.start_server(host, port, Multiplexer, ssl_config: @ssl, profile: @profile)
        puts "listening on #{host}:#{port}"
      end
    end
  end # Server
end # Proxy
