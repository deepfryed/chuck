module Chuck
  class Request < Swift::Scheme

    store :requests
    attribute :id,         Swift::Type::Integer,  key: true, serial: true
    attribute :session_id, Swift::Type::String
    attribute :rewritten,  Swift::Type::Boolean
    attribute :method,     Swift::Type::String
    attribute :uri,        Swift::Type::String
    attribute :version,    Swift::Type::String # http version
    attribute :headers,    Swift::Type::String,   default: proc { Headers.new }
    attribute :body,       Swift::Type::String
    attribute :created_at, Swift::Type::DateTime, default: proc { DateTime.now }

    def self.load tuple
      allocate.tap do |instance|
        instance.tuple   = tuple
        instance.headers = Headers.new Yajl.load(tuple[:headers] || '[]')
      end
    end

    def save
      id ? update : Request.create(self)
    end

    def to_s
      r  = "#{method} #{relative_uri} HTTP/#{version}\r\n"
      r += http_headers + "\r\n"
      r += body
    end

    def relative_uri
      abs  = uri.kind_of?(URI::HTTP) ? uri : URI.parse(uri)
      rel  = "#{abs.path}#{abs.fragment}"
      rel += "?#{abs.query}" if abs.query
      rel  = '/' + rel unless %r{^/}.match(rel)
      rel
    end

    def text?
      !!headers.find {|f, v| %r{content-type}i.match(f) && %r{^text/}i.match(v)}
    end

    def image?
      !!headers.find {|f, v| %r{content-type}i.match(f) && %r{^image/}i.match(v)}
    end

    # remove dupes, since strict request parsers will bomb out on duplicate keys.
    def http_headers
      seen = Hash.new(0)
      list = headers.entries.reverse.select {|key, value| seen[key] > 0 ? false : seen[key] += 1}.reverse
      list.map {|pair| pair.join(': ') + "\r\n"}.join
    end

    def connect?
      method == 'CONNECT'
    end

    def ssl?
      (URI === uri ? uri.port : URI.parse(uri).port) == 443
    end

    def response
      @response ||= Response.execute("select * from responses where request_id = ? limit 1", id).first
    end

    def self.recent
      execute("select * from requests where method != 'CONNECT' order by id desc")
    end

    # TODO: helpers that don't actually belong here
    def lifetime
      response && response.created_at ? response.created_at - created_at : 0
    end

    def status
      response && response.status
    end

    def curl
      "curl -X #{method} #{curl_headers} #{uri}"
    end

    def curl_headers
      headers.map {|pair| %Q{-H "#{pair.join(': ')}"}}.join(' ')
    end
  end
end
