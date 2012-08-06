module Chuck
  class Session < Swift::Record
    store :sessions
    attribute :id,         Swift::Type::String,   default: proc { UUID.generate }, key: true
    attribute :created_at, Swift::Type::DateTime, default: proc { DateTime.now  }
  end
end
