map 'http://www.google.com',    'http://www.google.com.au'
map 'http://www.google.com.au', 'http://localhost:3000'

map :post, 'http://www.example.com', 'http://localhost:3000' do |header|
  header.sub %r{\r\n\r\n}, "\r\nX-Proxy-Rewrite: 1\r\n\r\n"
end
