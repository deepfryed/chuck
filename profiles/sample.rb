map 'http://www.google.com',    'http://www.google.com.au'
map 'http://www.google.com.au', 'http://localhost:3000'

map :post, 'http://www.example.com', 'http://localhost:3000' do |data|
  data.sub %r{\r\n\r\n}, "\r\nX-Proxy-Rewrite: 1\r\n\r\n"
end

scope 'www.google.com', 443 do
  connect 'github.com', 443
  map '/', '/dashboard' do |data|
    data.sub "Host: www.google.com", "Host: github.com"
  end
end

on_request 'github.com' do |request, data|
  p request.headers.content
end

on_response 'github.com' do |response, data|
  p response.headers.content
end
