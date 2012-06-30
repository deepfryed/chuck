module Chuck
  class Response < Swift::Scheme
    store :responses
    attribute :id,         Swift::Type::Integer,  key: true, serial: true
    attribute :request_id, Swift::Type::Integer
    attribute :session_id, Swift::Type::String
    attribute :status,     Swift::Type::Integer
    attribute :headers,    Swift::Type::String
    attribute :body,       Swift::Type::String
    attribute :created_at, Swift::Type::DateTime

    def self.load tuple
      allocate.tap do |instance|
        instance.tuple   = tuple
        instance.headers = Headers.new Yajl.load(tuple[:headers] || '[]')
      end
    end

    def raw_headers
      headers.map {|pair| pair.join(': ')}.join($/)
    end

    def content_type
      pair = headers.find {|k, v| k.downcase == 'content-type'}
      pair && pair.last
    end

    def image?
      !!%r{^image/}.match(content_type)
    end

    def text?
      !!%r{^(?:text/|application/.*(?:json|xml))}.match(content_type)
    end
  end
end
