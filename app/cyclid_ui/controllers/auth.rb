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

require 'json'
require 'cyclid/client'

module Cyclid
  module UI
    module Controllers
      # Controller for authentication related endpoints
      class Auth < Base
        get '/login' do
          @message = flash[:login_error]
          @signup = Cyclid.config.signup
          mustache :login, layout: false
        end

        post '/login' do
          username = params[:username]
          password = params[:password]

          # Use the username & password to authenticate against the API; if
          # successful, it will return a JWT that can be used to authenticate
          # future requests
          begin
            Cyclid.logger.debug "api=#{Cyclid.config.server_api}"
            client = Client::Tilapia.new(auth: Client::AUTH_BASIC,
                                         log_level: Logger::DEBUG,
                                         server: Cyclid.config.server_api.host,
                                         port: Cyclid.config.server_api.port,
                                         username: username,
                                         password: password)
            token_data = client.token_get(username)
            Cyclid.logger.debug "got #{token_data}"
          rescue StandardError => ex
            Cyclid.logger.fatal "failed to get a token: #{ex}"
            halt_with_401
          end

          # At this point the user has authenticated successfully; get the user
          # information; the User model will cache it automatically.
          begin
            user = Models::User.get(username: username, password: password)
            Cyclid.logger.debug "user=#{user.to_hash}"
          rescue
            halt_with_401
          end

          # Store the username in the session
          session[:username] = username

          # Return the JWT cookie to the client as a cookie
          response.set_cookie('cyclid.token',
                              value: token_data['token'],
                              expires: Time.now + 21_600_000, # +6 hours
                              domain: Cyclid.config.domain,
                              path: '/',
                              http_only: false) # Must be available for AJAX

          # Pick the first organization from the users membership and
          # redirect; if the user doesn't belong to any organizations,
          # redirect them to their user page
          request_uri = session[:request_uri]
          Cyclid.logger.debug "request_uri=#{request_uri}"
          initial_page = if request_uri
                           request_uri
                         elsif user.organizations.empty?
                           if Cyclid.config.signup
                             "/user/#{username}/intro"
                           else
                             "/user/#{username}"
                           end
                         else
                           user.organizations.first
                         end

          redirect to initial_page
        end

        # Log out:
        #
        # 1. Delete the cached user object from Memcached
        # 2. Clear the session data
        # 3. Delete the API token cookie
        get '/logout' do
          authenticate!

          memcache = Memcache.new(server: Cyclid.config.memcached)
          begin
            memcache.expire(current_user.username)
          rescue Memcached::ServerIsMarkedDead => ex
            Cyclid.logger.fatal "cannot connect to memcached: #{ex}"
            # If Memcache is down there is nothing to expire
          end

          warden.logout
          cookies.delete 'cyclid.token'

          redirect to '/login'
        end
      end
    end
  end
end
