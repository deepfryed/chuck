module Chuck
  module Rack
    def self.request request
      env = {
        'rack.input'      =>  StringIO.new(request.body),
        'rack.url_scheme' =>  request.uri.scheme,
        'rack.version'    =>  [1, 0],
        'rack.errors'     =>  $stderr,
        'SERVER_SOFTWARE' =>  'Chuck Proxy',
        'SERVER_NAME'     =>  'chuck.in',
        'REQUEST_METHOD'  =>  request.method,
        'REQUEST_PATH'    =>  request.uri.path,
        'PATH_INFO'       =>  request.uri.path,
        'REQUEST_URI'     =>  request.uri.relative_uri,
        'HTTP_VERSION'    =>  'HTTP/%s' % request.version,
        'QUERY_STRING'    =>  request.uri.query,
        'CONTENT_LENGTH'  =>  request.body.bytesize,
      }

      request.headers.each do |field, value|
        env["HTTP_#{field.split(/-/).map(&:upcase).join('_')}"] = value
      end
      env
    end

    def self.response status, headers, body
      response = Response.new(status: status, headers: Headers.new, body: '', version: '1.1')
      body.each do |chunk|
        response.body << chunk
      end
      headers.each do |key, value|
        response.headers << [key, value]
      end

      response.headers.replace 'Content-Length', response.body.bytesize
      Response.create(response)
    end
  end # Rack
end # Chuck
