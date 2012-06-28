require 'haml'
require 'yajl/json_gem'
require 'sinatra/base'
require 'chuck/session'
require 'chuck/request'
require 'chuck/response'

module Chuck
  class Web < Sinatra::Base
    set :root, Chuck.root
    set :haml, escape_html: true, format: :html5

    attr_reader :resource

    helpers do
      def url *path
        params = path[-1].respond_to?(:to_hash) ? path.delete_at(-1).to_hash : {}
        params = params.empty? ? '' : '?' + URI.escape(params.map{|*a| a.join('=')}.join('&')).to_s
        ['/', path.compact.map(&:to_s)].flatten.join('/').gsub(%r{/+}, '/') + params
      end
    end

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

    error Sinatra::NotFound do
      '404 Not Found'
    end
  end
end
