# Rewriting HTTP Proxy in Ruby

A debugging proxy like Charles written in plain Ruby. You can more than simple rewriting since everything
is done in ruby.

* You can add, modify or delete headers.
* Do conditional rewrite based on request headers.
* Combine multiple profiles, chain rules.
* Generally, be more creative and productive.

## Setup

```
bundle --path gems --binstubs
```

## Profile

You need to setup a profile for rewriting urls. You can find a sample in `profiles/sample.rb`

```ruby
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
```

## Running

```
# terminal/screen 1
./bin/foreman start

# terminal/screen 2
curl -v --proxy 127.0.0.1:8080 http://www.google.com/hello-world
```

# See Also
[https://github.com/igrigorik/em-proxy](https://github.com/igrigorik/em-proxy)

## License
MIT
