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

require 'sinatra/cross_origin'

module Cyclid
  module UI
    module Controllers
      # Sinatra controller for user related endpoints
      class User < Base
        register Sinatra::CrossOrigin

        get '/user/:username' do
          authenticate!

          # Build breadcrumbs
          username = params[:username]

          @crumbs = []
          @crumbs << { 'name' => 'User' }
          @crumbs << { 'url' => "/user/#{username}", 'name' => username }

          @api_url = Cyclid.config.client_api
          @user_url = "#{@api_url}/users/#{params[:username]}"
          @current_user = current_user

          @organization = current_user.organizations.first

          mustache :user
        end

        post '/user/:username/invalidate' do
          cross_origin

          username = params[:username]

          payload = parse_request_body
          token = payload['token']

          # Ensure the User is removed from Memcached
          Models::User.invalidate(username: username, token: token)

          200
        end

        get '/user/:username/intro' do
          authenticate!

          # Build breadcrumbs
          username = params[:username]

          @crumbs = []
          @crumbs << { 'name' => 'User' }
          @crumbs << { 'url' => "/user/#{username}", 'name' => username }
          @crumbs << { 'url' => "/user/#{username}/intro", 'name' => 'Introduction' }

          @current_user = current_user

          mustache :intro
        end
      end
    end
  end
end
