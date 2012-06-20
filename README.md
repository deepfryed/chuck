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
map 'http://www.google.com',    'http://www.google.com.au'  # defaults to GET
map 'http://www.google.com.au', 'http://localhost:3000'     # defaults to GET

map :post, 'http://www.example.com', 'http://localhost:3000' do |header|
  header.sub %r{\r\n\r\n}, "\r\nX-Proxy-Rewrite: 1\r\n\r\n"
end
```

## Running

```
# terminal/screen 1
./bin/foreman start

# terminal/screen 2
curl -v http://www.google.com/hello-world --proxy 127.0.0.1:9889
```

## TODO

* Support for SSL

# See Also
[https://github.com/igrigorik/em-proxy](https://github.com/igrigorik/em-proxy)

## License
[Creative Commons Attribution - CC BY](http://creativecommons.org/licenses/by/3.0)
