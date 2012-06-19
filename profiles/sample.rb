rewrite %r{^GET http://www.google.com/(?<path>[^\s]*)(?<rest>.*)} do |match|
  "GET http://www.google.com.au/#{match[:path]} #{match[:rest]}"
end
