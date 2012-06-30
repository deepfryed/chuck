require 'thin'
require 'eventmachine'
require 'chuck/session'
require 'chuck/request'
require 'chuck/response'
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
      @ssl     = Chuck.ssl_config
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
        EM.start_server(host, port, Multiplexer, ssl_config: @ssl, profile: @profile, channel: stream.channel)
        Thin::Server.start(host, port + 1, Chuck::Web)

        puts "Chuck::Server - listening on #{ip}:#{port}"
        puts "Chuck::Web    - listening on #{ip}:#{port + 1}"

        puts $/
        puts "You should be able to view the logs at"
        puts "  * http://localhost:#{port + 1}/"
        puts "  * http://#{ip}:#{port + 1}/"
        puts $/
        puts "You should be able to retrieve the SSL CA certificate at"
        puts "  * http://#{ip}:#{port + 1}/c"
        puts $/

        Chuck.proxy_uri = "#{host}:#{port}"
      end
    end
  end # Server

  class Headers
    include Enumerable

    attr_reader :content

    def initialize content = []
      @content = content.flatten
      @state   = nil
    end

    def add type, value
      (@state == type ? @content.last : @content) << value
      @state = type
    end

    def to_s
      Yajl.dump(content)
    end

    def each &block
      @content.each_slice(2, &block)
    end

    def content
      @content.each_slice(2).entries
    end
  end # Headers
end # Chuck
