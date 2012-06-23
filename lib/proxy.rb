require 'logger'
require 'proxy/server'

module Proxy
  def self.root
    @root ||= Pathname.new(__FILE__).dirname + '..'
  end

  def self.ssl_config
    {cert_chain_file: (root + 'certs/server.crt').to_s, private_key_file: (root + 'certs/server.key').to_s}
  end

  def self.log message
   (@logger ||= proxy_logger).info(message)
  end

  def self.proxy_logger device = $stderr
    Logger.new(device, 0).tap do |logger|
      logger.formatter = proc do |sev, datetime, cli, message|
        "#{datetime.strftime('%F %T')}, #{message}#{$/}"
      end
    end
  end
end
