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
  end # Headers
end # Chuck
