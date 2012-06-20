# Rewriting HTTP Proxy in Ruby

Something like Charles without the Java crap.


## Setup

```
bundle --path gems --binstubs
``` 

## Profile

You need to setup a profile for rewriting urls. You can find a sample in `profiles/sample.rb`

## Running

```
# terminal/screen 1
./bin/proxy --profile profiles/sample.rb 

# terminal/screen 2
./bin/rackup -p 3000

# terminal/screen 3
curl -v http://www.google.com --proxy 127.0.0.1:9889 -o /dev/null
```

# See Also
[https://github.com/igrigorik/em-proxy](https://github.com/igrigorik/em-proxy)

## License
[Creative Commons Attribution - CC BY](http://creativecommons.org/licenses/by/3.0)
