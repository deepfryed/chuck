class Proxy::Profile
  MAX_REWRITES = 5

  def initialize files
    setup(files)
  end

  def process! buffer
    index = 0
    rewrite_count = 0
    while index < rules.size && rewrite_count < MAX_REWRITES
      re, callback = rules[index - 1]
      if match = re.match(buffer)
        log = ["rewriting request:", '', buffer.dup]
        buffer.sub!(re, callback.call(match))
        log << buffer.dup
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

    def map from, to
      rules << [%r{\AGET #{from}(?<rest>.*)\z}m, proc {|match| "GET #{to}#{match[:rest]}"}]
    end

    def rules
      @rules ||= []
    end
end # Proxy::Profile
