require 'haml'
require 'yajl/json_gem'
require 'sinatra/base'
require 'sinatra/content'
require 'chuck/session'
require 'chuck/request'
require 'chuck/response'

module Chuck
  class Web < Sinatra::Base
    set :root, Chuck.root
    set :haml, escape_html: true, format: :html5

    attr_reader :resource

    get '/' do
      @resource = Request.recent
      haml :'request/index'
    end

    get '/stream' do
      haml :stream
    end

    get '/session/:id' do |id|
      @resource = Session.get(id: id) or raise Sinatra::NotFound
      haml :'session/show'
    end

    get '/request/:id' do |id|
      @resource = Request.get(id: id) or raise Sinatra::NotFound
      haml :'request/show'
    end

    get '/response/:id' do |id|
      @resource = Response.get(id: id) or raise Sinatra::NotFound
      haml :'response/show'
    end

    get '/response/:id/body' do |id|
      resource = Response.get(id: id) or raise Sinatra::NotFound
      content_type resource.content_type
      resource.body
    end

    get '/c' do
      content_type 'application/x-x509-ca-cert'
      File.read(Chuck.root + 'certs/server.crt')
    end

    error Sinatra::NotFound do
      '404 Not Found'
    end
  end
end
