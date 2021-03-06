require 'forwardable'

module Chuck
  class Headers
    include Enumerable
    extend Forwardable

    def_delegators :content, :reject!, :<<

    attr_reader :content

    def initialize content = []
      @content = content
      @bucket  = []
      @state   = nil
    end

    def stream type, value
      (@state == type ? @bucket.last : @bucket) << value
      @state = type
    end

    def stream_complete
      @content += @bucket.each_slice(2).entries
      @bucket.clear
    end

    def replace key, value
      content.reject! {|f, v| f == key}
      content << [key, value]
    end

    def to_s
      Yajl.dump(content)
    end

    def each &block
      content.each(&block)
    end

    def << pair
      raise ArgumentError, "expected a key-value pair" unless Array === pair && pair.size == 2
      content << pair.map(&:to_s)
    end

    def [] key
      content.find {|k, v| k == key}
    end

    def to_http_header
      content.map {|pair| pair.join(': ') + "\r\n"}.join
    end
  end # Headers
end # Chuck
