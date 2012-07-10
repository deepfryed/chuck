require 'zlib'
require 'stringio'
require 'rack/utils'

module Chuck
  class Response < Swift::Scheme
    store :responses
    attribute :id,         Swift::Type::Integer,  key: true, serial: true
    attribute :request_id, Swift::Type::Integer
    attribute :session_id, Swift::Type::String
    attribute :status,     Swift::Type::Integer
    attribute :version,    Swift::Type::String # http version
    attribute :headers,    Swift::Type::String, default: proc { Headers.new }
    attribute :body,       Swift::Type::String
    attribute :created_at, Swift::Type::DateTime

    def self.load tuple
      allocate.tap do |instance|
        instance.tuple   = tuple
        instance.headers = Headers.new Yajl.load(tuple[:headers] || '[]')
      end
    end

    def request
      Request.get(id: request_id)
    end

    def save
      id ? update : Request.create(self)
    end

    def to_s
      r  = "HTTP/#{version} #{status} #{::Rack::Utils::HTTP_STATUS_CODES[status]}\r\n"
      r += http_headers + "\r\n"
      r += http_body
    end

    # preserve chunked response when serializing it.
    def http_body
      if headers.find {|pair| %r{transfer-encoding: chunked}i.match(pair.join(': '))}
        "#{tuple[:body].bytesize.to_s(16)}\r\n" + tuple[:body] + "\r\n0\r\n\r\n"
      else
        tuple[:body]
      end
    end

    def http_headers
      headers.map {|pair| pair.join(': ') + "\r\n"}.join
    end

    def body
      content = tuple[:body]
      if content.bytesize > 0
        case headers.map {|pair| pair.join(': ')}.join($/)
          when %r{Content-Encoding: +deflate}i
            content = Zlib::Inflate.inflate(content)
          when %r{Content-Encoding: +gzip}i
            zstream = Zlib::GzipReader.new(StringIO.new(content))
            content = zstream.read
            zstream.close
        end
      end
      content
    end

    # TODO: helpers that don't actually belong here
    def content_type
      pair = headers.find {|k, v| k.downcase == 'content-type'}
      pair && pair.last
    end

    def content_length
      body && body.bytesize
    end

    def image?
      !!%r{^image/}.match(content_type)
    end

    def text?
      !!%r{^(?:text/|application/.*(?:json|xml))}.match(content_type)
    end
  end
end
