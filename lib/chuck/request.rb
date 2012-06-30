module Chuck
  class Request < Swift::Scheme
    store :requests
    attribute :id,         Swift::Type::Integer,  key: true, serial: true
    attribute :session_id, Swift::Type::String
    attribute :rewritten,  Swift::Type::Boolean
    attribute :method,     Swift::Type::String
    attribute :uri,        Swift::Type::String
    attribute :headers,    Swift::Type::String
    attribute :body,       Swift::Type::String
    attribute :created_at, Swift::Type::DateTime, default: proc { DateTime.now }

    def connect?
      method == 'CONNECT'
    end

    def ssl?
      (URI === uri ? uri.port : URI.parse(uri).port) == 443
    end

    def response
      @response ||= Response.execute("select * from responses where request_id = ? limit 1", id).first
    end

    def raw_headers
      Yajl.load(headers).map {|pair| pair.join(': ')}.join($/)
    end

    def lifetime
      response ? response.created_at - created_at : 0
    end

    def content_type
      response && response.content_type
    end

    def status
      response && response.status
    end

    def curl
      "curl -X #{method} #{curl_headers} #{uri}"
    end

    def curl_headers
      (String === headers ? Yajl.load(headers) : headers).map {|pair| %Q{-H "#{pair.join(': ')}"}}.join(' ')
    end

    def self.recent
      execute("select * from requests where method != 'CONNECT' order by id desc")
    end
  end
end
