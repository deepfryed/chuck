require 'proxy/server'

module Proxy
  def self.root
    @root ||= Pathname.new(__FILE__).dirname + '..'
  end

  def self.ssl_config
    {cert_chain_file: (root + 'certs/server.crt').to_s, private_key_file: (root + 'certs/server.key').to_s}
  end
end
