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

    banner! if options[:help]
  end

  def banner!
    puts <<-EOM

      #{$0} [options]

      --profile file
      --host    host  # proxy host, default 0.0.0.0
      --port    port  # proxy port, default 9889
      --help

    EOM
    exit
  end

  HOST_PORT_RE = %r{^(?:GET|POST|PUT|DELETE|OPTIONS|TRACE)\s+https?://(?<host>[^/]+)/?(?:[^:]*)(?::(?<port>\d+)).*}i

  def run
    profile = Proxy::Profile.new(options.fetch(:profile, nil))
    logger  = Logger.new(options.fetch(:log, $stderr), 0)
    logger.info "listening on #{host}:#{port}..."
    logger.level = Logger::INFO

    Proxy.start(host: host, port: port) do |conn|
      @p = Http::Parser.new
      @p.on_headers_complete = proc do |h|
        session = UUID.generate
        logger.info "new session: #{session} (#{h.inspect})"

        profile.process!(@buffer) {|message| logger.info message}

        host, port = h['Host'].split(':')

        # rewrite Host header and connect endpoint.
        if server = @buffer.match(HOST_PORT_RE)
          host, port = $~[:host], $~[:port]
          @buffer.sub! %r{^Host:\s+.*?\r\n}m, "Host: #{host}\r\n"
        end

        conn.server session, host: host, port: (port || 80)
        conn.relay_to_servers @buffer
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
