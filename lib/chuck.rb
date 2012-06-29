require 'pathname'

module Chuck
  class << self
    attr_accessor :proxy_uri

    def root
      @root ||= Pathname.new(__FILE__).dirname + '..'
    end

    def ssl_config
      {cert_chain_file: (root + 'certs/server.crt').to_s, private_key_file: (root + 'certs/server.key').to_s}
    end

    def log_error e
      $stderr.puts "ERROR: #{e.message}"
      $stderr.puts e.backtrace.take(20).join($/)
    end
  end # self
end # Chuck
