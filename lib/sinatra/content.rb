require 'sinatra/base'

module Sinatra
  class Base
    module Content
      def content name, &block
        @content ||= Hash.new{|h, k| h[k] = []}
        @content[name] << block if block
        @content[name]
      end

      def yield_content name, *args
        content(name).each do |block|
          haml_concat(capture_haml(*args, &block).strip) if block_is_haml?(block)
        end
      end

      def get_content name, *args
        capture_haml{ yield_content(name, *args) }
      end

      def has_content? name
        @content && @content.key?(name)
      end

      def url *path
        params = path[-1].respond_to?(:to_hash) ? path.delete_at(-1).to_hash : {}
        params = params.empty? ? '' : '?' + URI.escape(params.map{|*a| a.join('=')}.join('&')).to_s
        ['/', path.compact.map(&:to_s)].flatten.join('/').gsub(%r{/+}, '/') + params
      end

      def page_id
        path = request.path_info.split('/').compact.reject(&:empty?)
        if path.empty?
          'page_home'
        else
          'page_%s' % path.join('_')
        end
      end
    end

    helpers Content
  end # Base
end # Sinatra
