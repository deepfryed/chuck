module Proxy
  class Response < Swift::Scheme
    store :responses
    attribute :id,         Swift::Type::Integer,  key: true, serial: true
    attribute :request_id, Swift::Type::Integer
    attribute :session_id, Swift::Type::String
    attribute :status,     Swift::Type::Integer
    attribute :headers,    Swift::Type::String
    attribute :body,       Swift::Type::String
    attribute :created_at, Swift::Type::DateTime

    def self.find_by attrs = {}
      execute("select * from #{self} where #{filter_by(attrs)} limit 1", *attrs.values).first
    end

    def self.filter_by attrs
      attrs.keys.map {|name| '%s = ?' % name}.join(' and ')
    end
  end
end
