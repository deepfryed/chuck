#!/usr/bin/env ruby

require 'haml'

module Chuck
  class Render
    def self.haml template, locals = {}
      haml = Haml::Engine.new(File.read(Chuck.root + 'views' + template))
      haml.render(self, locals)
    end

    module Url
      def url *path
        params = path[-1].respond_to?(:to_hash) ? path.delete_at(-1).to_hash : {}
        params = params.empty? ? '' : '?' + URI.escape(params.map{|*a| a.join('=')}.join('&')).to_s
        ['/', path.compact.map(&:to_s)].flatten.join('/').gsub(%r{/+}, '/') + params
      end
    end # Url

    extend Url
  end # Render
end # Chuck
