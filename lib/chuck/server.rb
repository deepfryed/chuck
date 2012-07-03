require 'thin'
require 'eventmachine'
require 'chuck/session'
require 'chuck/request'
require 'chuck/response'
require 'chuck/headers'
require 'chuck/multiplexer'
require 'chuck/backend'
require 'chuck/web'
require 'chuck/stream'
require 'socket'

module Chuck
  class Server
    attr_reader :host, :port
    def initialize options = {}
      @host    = '0.0.0.0'
      @port    = options.fetch(:port,    8080)
      @profile = options.fetch(:profile, Dir[Chuck.root + 'profiles/sample.rb'])
    end

    def ip
      Socket.ip_address_list.select(&:ipv4?).reject(&:ipv4_loopback?).first.ip_address
    end

    def stop *args
      puts $/, "Chuck::Server - shutting down"
      EM.stop
    end

    def start
      %w(INT HUP TERM).each {|name| Signal.trap(name,  &method(:stop))}

      EM.run do
        stream = Stream.new(host, 8998)
        stream.run

        Multiplexer.listen(host, port, profile: @profile, channel: stream.channel)
        Thin::Server.start(host, port + 1, Chuck::Web)

        puts $/
        puts "Chuck::Server - listening on #{ip}:#{port}"
        puts "Chuck::Web    - listening on #{ip}:#{port + 1}"
        puts "Chuck::Stream - listening on #{ip}:8998"

        puts $/
        puts "You should point your mobile device or browser at the proxy server below"
        puts "  * #{ip}:#{port}"
        puts $/
        puts "You should be able to view the logs at"
        puts "  * http://localhost:#{port + 1}/"
        puts "  * http://#{ip}:#{port + 1}/"
        puts $/
        puts "You should be able to retrieve the SSL CA certificate at"
        puts "  * http://#{ip}:#{port + 1}/c"
        puts $/
      end
    end
  end # Server
end # Chuck
