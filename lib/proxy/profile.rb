class Proxy::Profile
  def initialize file
    setup(file)
  end

  def process buffer
    rules.each do |re, callback|
      if match = re.match(buffer)
        yield "rewriting request with #{match}" if block_given?
        buffer.sub!(re, callback.call(match))
        break
      end
    end
    buffer
  end

  private
    def setup file
      return unless file
      instance_eval File.read(file)
    end

    def rewrite regex, &callback
      rules[regex] = callback
    end

    def rules
      @rules ||= {}
    end
end
