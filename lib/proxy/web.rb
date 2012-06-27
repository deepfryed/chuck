module Proxy
  class Web < Sinatra::Base
    get '/session/:id' do |id|
      @session = Session.get(id: id) or raise Sinatra::NotFound
      haml :session
    end

    get '/request/:id' do |id|
      @request = Request.get(id: id) or raise Sinatra::NotFound
      haml :request
    end

    get '/response/:id' do |id|
      @response = Response.get(id: id) or raise Sinatra::NotFound
      haml :response
    end
  end
end
