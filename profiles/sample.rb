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
  print  "%s - "   % Time.now.strftime('%F %T')
  print  "%5s %s " % [request.method, request.uri]
end

on_response 'github.com' do |response|
  print  "%s %d %s" % [response.status, response.body.bytesize, response.headers.select {|k, v| k == 'Server'}]
  puts   $/, '-' * 80
end

on_request do |request|
  print  "%s - "   % Time.now.strftime('%F %T')
  print  "%5s %s " % [request.method, request.uri]
end

on_response do |response|
  print  "%s %d  " % [response.status, response.body.bytesize]
  puts   $/, '-' * 80
end
