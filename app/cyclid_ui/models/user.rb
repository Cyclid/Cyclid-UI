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

module Cyclid
  module UI
    module Models
      # A User object. This is really no more than a simple wrapper around the
      # Cyclid user data that is returned from the API, with the added layer
      # of Memecached caching of the object to avoid API calls.
      class User
        attr_reader :username, :email, :name, :organizations, :id

        def initialize(args = {})
          @username = args['username'] || nil
          @email = args['email'] || nil
          @name = args['name'] || nil
          @organizations = args['organizations'] || []
          @id = args['id'] || nil
        end

        def to_hash
          { 'username' => @username,
            'email' => @email,
            'name' => @name,
            'organizations' => @organizations,
            'id' => @id }
        end

        # Try to find the user object in Memcached; if it does not exist,
        # fallback to the API. If the API returns the user data, it will be
        # cached into Memcache for future use.
        #
        # If we have to fall back to the API we assume that the username is
        # valid and either the HTTP Basic password or an API token are available
        # and valid.
        def self.get(args)
          username = args[:username] || args['username']
          memcache = Memcache.new(server: Cyclid.config.memcached)

          user_data = begin
                        memcache.cache username do
                          user_fetch(args)
                        end
                      rescue Memcached::ServerIsMarkedDead => ex
                        Cyclid.logger.fatal "cannot connect to memcached: #{ex}"
                        # Fall back to a direct API connection
                        user_fetch(args)
                      end

          new(user_data)
        end

        def self.user_fetch(args)
          username = args[:username] || args['username']
          password = args[:password] || args['password']
          token = args[:token] || args['token']

          auth_method = token.nil? ? Client::AUTH_BASIC : Client::AUTH_TOKEN

          user_data = nil
          begin
            Cyclid.logger.debug "api=#{Cyclid.config.server_api.inspect}"
            client = Client::Tilapia.new(auth: auth_method,
                                         server: Cyclid.config.server_api.host,
                                         port: Cyclid.config.server_api.port,
                                         username: username,
                                         password: password,
                                         token: token)
            user_data = client.user_get(username)
            Cyclid.logger.debug "got #{user_data}"
          rescue StandardError => ex
            Cyclid.logger.fatal "failed to get user details: #{ex}"
            raise ex
          end

          user_data
        end
      end
    end
  end
end
