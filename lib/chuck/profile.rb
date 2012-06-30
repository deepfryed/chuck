module Chuck
  class Profile
    MAX_REWRITES = 5
    SEPERATOR    = '~' * 80

    attr_reader :host, :port

    def initialize files = []
      setup(files)
    end

    def process! buffer
      index = 0
      rewrite_count = 0
      while index < rules.size && rewrite_count < MAX_REWRITES
        re, callback = rules[index - 1]
        if match = re.match(buffer)
          buffer.sub!(re, callback.call(match))
          # restart the matching for cascaded rewriting.
          index = 0
          rewrite_count += 1
        end
        index += 1
      end
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

      def on_request host, &callback
        callbacks[:request][host] = callback
      end

      def on_response host, &callback
        callbacks[:response][host] = callback
      end

      def rewrite regex, &callback
        rules << [regex, callback]
      end

      def map *args, &callback
        raise ArgumentError, "wrong number of arguments(#{args.size} for 2..3)" if args.size < 2 or args.size > 3
        verb, from, to = args.size == 2 ? ['GET', *args] : args
        verb = verb.to_s.upcase
        port = from.match(%r{https://}i) ? 443 : 80
        re   = %r{\A#{verb} #{from}(?<port>:#{port})?(?<path>/[^\s]*)? (?<rest>.+)\z}m

        if callback
          rewrite(re) do |match|
            callback.call("#{verb} #{to}#{match[:path]} #{match[:rest]}")
          end
        else
          rewrite(re) do |match|
            "#{verb} #{to}#{match[:path]} #{match[:rest]}"
          end
        end
      end

      def scope name, port, &block
        (scopes[scope_key(name, port)] ||= Profile.new).instance_eval(&block)
      end

      def rules
        @rules ||= []
      end

      def connect host, port
        @host, @port = host, port
      end
  end # Profile
end # Chuck
