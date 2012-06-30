module Chuck
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
