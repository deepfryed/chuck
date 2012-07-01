require 'swift'
require 'logger'
require 'pathname'

module Chuck
  class << self
    def root
      @root ||= Pathname.new(__FILE__).dirname + '..'
    end

    def logger
      @logger ||= Logger.new($stderr, 0)
    end

    def logger= logger
      @logger = logger
    end

    def log_error e
      logger.error e.message
      logger.error e.backtrace.take(20).join($/)
    end
  end # self
end # Chuck
