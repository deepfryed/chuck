require 'thin'
require 'pathname'
require 'eventmachine'
require 'chuck/session'
require 'chuck/request'
require 'chuck/response'
require 'chuck/multiplexer'
require 'chuck/backend'
require 'chuck/web'

module Chuck
  class Server
    attr_reader :host, :port
    def initialize options = {}
      @host     = options.fetch(:host,   '0.0.0.0')
      @port     = options.fetch(:port,    8080)
      @profile  = options.fetch(:profile, Dir[Chuck.root + 'profiles/sample.rb'])
      @ssl      = Chuck.ssl_config
    end

    def stop *args
      puts $/, "Chuck::Server - shutting down"
      EM.stop
    end

    def start
      %w(INT HUP TERM).each {|name| Signal.trap(name,  &method(:stop))}

      EM.run do
        EM.start_server(host, port, Multiplexer, ssl_config: @ssl, profile: @profile)
        Thin::Server.start(host, port + 1, Chuck::Web)
        puts "Chuck::Server - listening on #{host}:#{port}"
        puts "Chuck::Web    - listening on #{host}:#{port + 1}"

        puts $/, "You should be able to view the logs at http://localhost:#{port + 1}/", $/
        Chuck.proxy_uri = "#{host}:#{port}"
      end
    end
  end # Server
end # Chuck
