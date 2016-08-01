# frozen_string_literal: true
# Modified from https://gist.github.com/mralex/956592
#
# Original licensed under MIT: https://github.com/gioext/sinatra-memcache
require 'memcached'

module Cyclid
  module UI
    # Simple Memcache caching layer on top of the Memcached client. Keys are
    # retrieved or set via. the cache method; if the key exists it is returned,
    # if the key does not exist the given block is called and its output is
    # stored in Memcached.
    class Memcache
      attr_reader :client, :server, :expiry

      def initialize(args)
        @server = args[:server]
        @expiry = args[:expiry] || 3600
      end

      def cache(key)
        begin
          output = memcached.get(key)
        rescue Memcached::NotFound
          output = yield
          memcached.set(key, output, @expiry)
        end
        output
      end

      def expire(key)
        memcached.delete key
        true
      rescue Memcached::NotFound
        false
      end

      private

      def memcached
        @client ||= Memcached.new(@server)
      end
    end
  end
end
