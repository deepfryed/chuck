module Chuck
  module Backend
    attr_reader :host, :port
    def initialize options
      @buffer   = ''
      @plexer   = options.fetch(:plexer)
      @host     = options.fetch(:host)
      @port     = options.fetch(:port)
      @request  = options.fetch(:request)
      @headers  = Headers.new
      @response = Response.create(request_id: @request.id, session_id: @request.session_id, body: '')
      @parser   = HTTP::Parser.new

      %w(on_message_complete on_header_field on_header_value on_body).each do |name|
        @parser.send(name, &method(name.to_sym))
      end
    end

    def on_header_field value
      @headers << value
    end

    def on_header_value value
      @headers << value
    end

    def on_body data
      @response.body << data
    end

    def on_message_complete
      @response.body.force_encoding(Encoding::UTF_8)
      @response.update(created_at: DateTime.now, status: @parser.http_status, headers: @headers)
      @plexer.forward_to_client(@buffer)
      @parser.reset
      @buffer = ''
    end

    def post_init
      start_tls if @ssl
    end

    def receive_data data
      @buffer << data
      @parser << data
    rescue => e
      Chuck.log_error(e)
      unbind
    end

    def unbind
      @plexer.finish
      @plexer.close_connection(true)
    end
  end # Backend
end # Chuck
