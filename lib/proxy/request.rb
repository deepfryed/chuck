module Proxy
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
  end
end
