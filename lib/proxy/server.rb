#!/usr/bin/env ruby

require 'bundler/setup'
require 'em-proxy'
require 'http/parser'
require 'uuid'
require 'logger'
require 'proxy/profile'
require 'options_parser'

class Proxy::Server

  attr_reader :profile, :host, :port, :options

  def initialize
    @options = OptionsParser.new(ARGV).options
    @host    = options.fetch(:host, '0.0.0.0')
    @port    = options.fetch(:port , 9889)
  end

  def run
    profile = Proxy::Profile.new(options.fetch(:profile, nil))
    logger  = Logger.new(options.fetch(:log, $stderr), 0)
    logger.info "listening on #{host}:#{port}..."
    logger.level = Logger::ERROR

    Proxy.start(host: host, port: port) do |conn|
      @p = Http::Parser.new
      @p.on_headers_complete = proc do |h|
        session = UUID.generate
        logger.info "new session: #{session} (#{h.inspect})"

        host, port = h['Host'].split(':')
        conn.server session, host: host, port: (port || 80)
        conn.relay_to_servers profile.process(@buffer)
        @buffer.clear
      end

      @buffer = ''

      conn.on_connect do |data, b|
        logger.debug ":on_connect | #{data} | #{b}"
      end

      conn.on_data do |data|
        @buffer << data
        @p << data
        data
      end

      conn.on_response do |backend, resp|
        logger.debug ":on_connect | #{backend} | #{resp}"
        resp
      end

      conn.on_finish do |backend, name|
        logger.debug ":on_connect | #{backend} | #{name}"
      end
    end
  end # run
end # Proxy::Server
