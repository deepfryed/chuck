# Chuck - A Debugging HTTP Proxy in Ruby

A debugging proxy like CharlesProxy written in plain Ruby. You can intercept requests,
redirect or rewrite them using simple callbacks.

## Features

* Add, modify or delete headers.
* Do conditional rewrite based on request headers.
* Combine multiple profiles, chain rules.
* Generally, be more creative and productive.

## Setup

Install dbic++ with sqlite3 first

* https://github.com/deepfryed/dbicpp#debian
* https://github.com/deepfryed/dbicpp#macosx (`brew install https://raw.github.com/deepfryed/dbicpp/master/brew/dbicpp.rb`)

Install the gem dependencies next

```
bundle --path gems --binstubs
```

## Profile

You need to setup a profile for rewriting urls. You can find a sample in `profiles/sample.rb`

```ruby
map 'http://www.google.com',    'http://www.google.com.au'
map 'http://www.google.com.au', 'http://localhost:3000'

scope 'www.google.com', 443 do
  connect 'github.com', 443
  map 'https://github.com/', 'https://github.com/dashboard' do |request|
    request.headers.replace 'Host', 'github.com'
  end

  on_response do |response|
    response.headers.replace 'X-FooBar-Key', 'test'
  end
end

mock 'http://www.cnn.com', Class.new(Sinatra::Base) { get(%r{/.*}) { 'hot news'} }

on_request 'example.com' do |request|
  halt_request(request, 200, {}, 'hello world!')
end

```

## Running

```
# terminal/screen 1
./bin/foreman start

# terminal/screen 2
curl -v -k --proxy 127.0.0.1:8080 http://www.google.com/hello-world
curl -v -k --proxy 127.0.0.1:8080 https://www.google.com/
curl -v -k --proxy 127.0.0.1:8080 http://www.cnn.com/
```

## Logs

Go to [http://localhost:8081/](http://localhost:8081/) or whatever url chuck displays.


## Chuck SSL CA

Chuck uses a self-signed certificate to construct SSL certificates on the fly. This will trigger warnings in
your browser or applications.

To get around those, add Chuck's cerificate as a trusted authority in your browser or mobile device.

* iPhone, Android: navigate to the CA url displayed on console when you run Chuck
* Firefox, etc: Add `certs/server.crt` to your trusted certificates list
* openssl on debian:

```
sudo cp certs/server.crt /etc/ssl/certs/chuck-proxy.pem
cd /etc/ssl/certs
sudo ln -s chuck-proxy.pem `openssl x509 -noout -hash -in chuck-proxy.pem`.0
cd -
```

## Notes

* The proxy always intercepts SSL requests even if there is no remap of request, this is not ideal.
* There is no proxy keep-alive support yet.

# See Also
[https://github.com/igrigorik/em-proxy](https://github.com/igrigorik/em-proxy)

## License
GPLv3
