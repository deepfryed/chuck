# Rewriting HTTP Proxy in Ruby

Something like Charles without the Java crap.


## Setup

```
bundle --path gems
``` 

## Profile

You need to setup a profile for rewriting urls. You can find a sample in `profiles/sample.rb`

## Running

```
# from down under, ymmv

curl -v http://www.google.com -o /dev/null

# another screen/terminal
./bin/proxy --profile profiles/sample.rb 

# switch screen/terminal
curl -v http://www.google.com --proxy 127.0.0.1:9889 -o /dev/null
```

# See Also
[https://github.com/igrigorik/em-proxy](https://github.com/igrigorik/em-proxy)

## License
[Creative Commons Attribution - CC BY](http://creativecommons.org/licenses/by/3.0)
