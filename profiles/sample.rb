map 'http://www.google.com.au', 'http://localhost:3000'

rewrite %r{\AGET http://www.google.com(/(?<path>[^\s]*)(?<rest>.+))?\z}m do |match|
  "GET http://www.google.com.au/#{match[:path]}#{match[:rest]}"
end
