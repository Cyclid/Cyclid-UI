# Taken from https://gist.github.com/mralex/956592
#
# Original licensed under MIT: https://github.com/gioext/sinatra-memcache
require 'sinatra/base'
require 'memcached'

module Sinatra
  module Memcacher
    module Helpers
      def cache(key, &block)
        return block.call unless options.memcacher_enabled
                  
        begin
          output = memcached.get(key)
        rescue Memcached::NotFound
          output = block.call
          memcached.set(key, output, options.memcacher_expiry)
        end
        output
      end
      
      def expire(key)
        begin
          memcached.delete key
          true
        rescue Memcached::NotFound
          false
        end
      end
  
      private
  
      def memcached
        options.memcacher_client ||= Memcached.new(options.memcacher_server)
      end
    end
    
    def self.registered(app)
      app.helpers Memcacher::Helpers
      
      app.set :memcacher_client, nil
      app.set :memcacher_enabled, false
      app.set :memcacher_server, "127.0.0.1:11211"
      app.set :memcacher_expiry, 3600
    end
  end
  
  register Memcacher
end
