map 'http://www.google.com',    'http://www.google.com.au'
map 'http://www.google.com.au', 'http://localhost:3000'

map 'http://www.example.com', 'http://localhost:3000' do |request|
  request.headers.content << "X-Proxy-Rewrite" << 1
end

scope 'www.google.com', 443 do
  connect 'github.com', 443
  map 'https://github.com/', 'https://github.com/dashboard' do |request|
    request.headers.replace 'Host', 'github.com'
  end
end

on_request 'github.com' do |request|
  print request.session_id, ": ", request.uri, $/
end

on_response 'github.com' do |response|
  print response.session_id, ": ", response.status, $/
end

on_request do |request|
  puts request.uri
end

on_response do |response|
  puts response.status
end

mock 'http://www.cnn.com', Class.new(Sinatra::Base) { get(%r{/.*}) { 'hot news'} }
