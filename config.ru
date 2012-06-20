require 'bundler/setup'
require 'sinatra/base'
require 'json'

class MyApp < Sinatra::Base  

  helpers do
    def request_info
      request.env.reject {|k, v| %r{^(?:rack|async).}.match(k)}
    end
  end

  before do
    content_type :json
  end

  get %r{.*} do
    JSON.pretty_generate(request_info)
  end
end

run MyApp
