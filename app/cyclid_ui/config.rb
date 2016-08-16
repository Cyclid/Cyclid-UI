# frozen_string_literal: true
# Copyright 2016 Liqwyd Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'yaml'
require 'uri'

module Cyclid
  module UI
    # Cyclid UI configuration
    class Config
      attr_reader :memcached, :log, :server_api, :client_api

      def initialize(path)
        # Try to load the configuration file. If it can't be loaded, we'll
        # fall back to defaults
        begin
          config = YAML.load_file(path)
          manage = config['manage'] || {}
        rescue Errno::ENOENT
          # Cyclid.logger wont exist, yet
          STDERR.puts "Config file #{path} not found: using defaults"
          manage = {}
        end

        @memcached = manage['memcached'] || 'localhost:11211'
        @log = manage['log'] || File.join(%w(/ var log cyclid manage))

        # The api setting is flexible; the URL that the server uses to connect
        # to the API, and the URL that the client uses, can be diferent. This
        # may happen if E.g. the UI & API are running on the same machine but
        # with the ports NAT'd from the outside so that the client sees port
        # 8123 but the local port is 123, or where the API is behind a load
        # balancer and you may wish to avoid the round-trip out and back in.
        #
        # If "api" is a string then it is used for both the server & client URL
        # If "api" is an array then we select the client & server URLs
        # separately
        api = manage['api'] || 'http://localhost:8361'
        if api.is_a? String
          @server_api = URI(api)
          @client_api = URI(api)
        elsif api.is_a? Hash
          @server_api = URI(api['server'])
          @client_api = URI(api['client'])
        end

      rescue StandardError => ex
        abort "Failed to load configuration file #{path}: #{ex}"
      end
    end
  end
end
