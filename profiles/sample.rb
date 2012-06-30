map 'http://www.google.com',    'http://www.google.com.au'
map 'http://www.google.com.au', 'http://localhost:3000'

map :post, 'http://www.example.com', 'http://localhost:3000' do |header|
  header.sub %r{\r\n\r\n}, "\r\nX-Proxy-Rewrite: 1\r\n\r\n"
end

scope 'www.google.com', 443 do
  connect 'github.com', 443
  map '/', '/dashboard' do |header|
    header.sub "Host: www.google.com", "Host: github.com"
  end
end

on_request 'github.com' do |request, raw|
  p request.headers.content
  raw
end

on_response 'github.com' do |response, raw|
  p response.headers.content
  raw
end
