module Chuck
  class Condition
    attr_reader :options

    def initialize options
      @options = options
    end

    def match? request
      options.each do |key, value|
        case key
          when :method
            return false unless request.method.downcase == value.downcase
          when :uri
            return false unless value.match(request.uri.to_s)
          when :host
            return false unless request.uri.host.downcase == value.downcase
          when :port
            return false unless request.uri.port == value.to_i
        end
      end
      return true
    end
  end # Condition
end # Chuck
