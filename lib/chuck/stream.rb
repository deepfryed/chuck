require 'em-websocket'

module Chuck
  class Stream
    attr_reader :channel, :host, :port

    def initialize host, port
      @host    = host
      @port    = port
      @channel = EM::Channel.new
    end

    def run
      EM::WebSocket.start(host: host, port: port, debug: false) do |ws|
        ws.onopen do
          id = channel.subscribe {|msg| ws.send(msg)}
          ws.onclose do
            channel.unsubscribe(id)
          end
        end
      end
    end
  end
end
