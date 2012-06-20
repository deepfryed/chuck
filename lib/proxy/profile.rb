class Proxy::Profile
  MAX_REWRITES = 5
  SEPERATOR    = '~' * 80

  def initialize files
    setup(files)
  end

  def process! buffer
    index = 0
    rewrite_count = 0
    while index < rules.size && rewrite_count < MAX_REWRITES
      re, callback = rules[index - 1]
      if match = re.match(buffer)
        log = ["rewriting request:", SEPERATOR, buffer.dup, SEPERATOR]
        buffer.sub!(re, callback.call(match))
        log << buffer.dup << SEPERATOR
        yield log.join($/) if block_given?

        # restart the matching for cascaded rewriting.
        index = 0
        rewrite_count += 1
      end
      index += 1
    end
  end

  private
    def setup files
      [files].flatten.each do |file|
        instance_eval File.read(file)
      end
    end

    def rewrite regex, &callback
      rules << [regex, callback]
    end

    def map *args, &callback
      raise ArgumentError, "wrong number of arguments(#{args.size} for 2..3)" if args.size < 2 or args.size > 3
      verb, from, to = args.size == 2 ? ['GET', *args] : args
      verb = verb.to_s.upcase
      re   = %r{\A#{verb} #{from}(?<rest>.*)\z}m

      if callback
        rewrite(re) do |match|
          callback.call("#{verb} #{to}#{match[:rest]}")
        end
      else
        rewrite(re) do |match|
          "#{verb} #{to}#{match[:rest]}"
        end
      end
    end

    def rules
      @rules ||= []
    end
end # Proxy::Profile
