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
      Response.execute("select * from responses where request_id = ? limit 1", id).first
    end

    def raw_headers
      Yajl.load(headers).map {|pair| pair.join(': ')}.join($/)
    end

    def lifetime
      tuple[:finished_at] ? (tuple[:finished_at] - created_at) : 0
    end

    def status
      tuple[:status] || response.status
    end

    def self.recent
      execute(%q{
        select r.*, re.created_at as finished_at, re.status
        from requests r join responses re on (re.request_id = r.id)
        order by r.id desc
      })
    end
  end
end
