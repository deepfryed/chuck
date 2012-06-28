require 'swift'
require 'chuck/server'

module Chuck
  def self.root
    @root ||= Pathname.new(__FILE__).dirname + '..'
  end

  def self.ssl_config
    {cert_chain_file: (root + 'certs/server.crt').to_s, private_key_file: (root + 'certs/server.key').to_s}
  end

  def self.log_error e
    $stderr.puts "ERROR: #{e.message}"
    $stderr.puts e.backtrace.take(20).join($/)
  end
end
