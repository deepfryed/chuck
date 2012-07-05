require 'chuck/condition'
require 'chuck/rack'

module Chuck
  class Profile
    attr_reader :host, :port

    def initialize files = []
      setup(files)
    end

    def process! request
      rules.each do |condition, processor|
        processor.call(request) if condition.match?(request)
      end
      nil
    end

    def callbacks
      @callbacks ||= {request: {}, response: {}}
    end

    def scope_key host, port
      "#{host}:#{port}"
    end

    def scopes
      @scopes ||= {}
    end

    private
      def setup files
        [files].flatten.each do |file|
          instance_eval File.read(file)
        end
      end

      def on_request host = nil, &callback
        callbacks[:request][host] = callback
      end

      def on_response host = nil, &callback
        callbacks[:response][host] = callback
      end

      def rules
        @rules ||= []
      end

      def capture condition, &callback
        rules << [Condition.new(condition), callback]
      end

      def mock from, app
        capture(uri: from_re(from)) do |request|
          response = Rack.response(*app.call(Rack.request(request)))
          response.update(request_id: request.id, session_id: request.session_id)
          throw :halt, response
        end
      end

      def map from, to, &callback
        to = URI.parse(to)
        raise ArgumentError, "to needs to be http:// or https:// uris" unless %r{https?}i.match(to.scheme)

        capture(uri: from_re(from)) do |request|
          request.uri = to + request.relative_uri
          begin
            callback.call(request) if callback
          rescue => e
            Chuck.log_error(e)
          end
        end
      end

      def from_re from
        case from
          when Regexp
            from
          when %r{^https?://}i
            %r{^#{from}}
          else
            raise ArgumentError, "from needs to be a Regexp or http:// or https:// uri"
        end
      end

      def scope name, port, &block
        (scopes[scope_key(name, port)] ||= Profile.new).instance_eval(&block)
      end

      def connect host, port
        @host, @port = host, port
      end
  end # Profile
end # Chuck
