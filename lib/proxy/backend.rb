module Proxy
  module Backend
    def initialize plexer, ssl
      @buffer = ''
      @plexer = plexer
      @ssl    = ssl
      @parser = HTTP::Parser.new
      @parser.on_message_complete(&method(:on_message))
    end

    def post_init
      start_tls if @ssl
    end

    def on_message
      @plexer.forward_to_client(@buffer)
      @buffer = ''
      @parser.reset
    end

    def receive_data data
      @buffer << data
      @parser << data
    rescue => e
      unbind
    end

    def unbind
      @plexer.finish
      @plexer.close_connection(true)
    end
  end # Backend
end # Proxy
