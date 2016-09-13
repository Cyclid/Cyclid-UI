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

require 'require_all'
require 'logger'
require 'warden'
require 'memcached'
require 'sinatra/flash'
require 'rack/csrf'

require_rel 'cyclid_ui/config'
require_rel 'cyclid_ui/memcache'
require_rel 'cyclid_ui/helpers'

require_rel 'cyclid_ui/models'
require_rel 'cyclid_ui/controllers'

require_rel 'cyclid_ui/views'

# Namespace for all Cyclid UI related code
module Cyclid
  class << self
    attr_accessor :config, :logger

    config_path = ENV['CYCLID_CONFIG'] || File.join(%w(/ etc cyclid config))
    Cyclid.config = UI::Config.new(config_path)

    begin
      Cyclid.logger = if Cyclid.config.log.casecmp('stderr').zero?
                        Logger.new(STDERR)
                      else
                        Logger.new(Cyclid.config.log)
                      end
    rescue StandardError => ex
      abort "Failed to initialize: #{ex}"
    end
  end
end

module Cyclid
  module UI
    # Sinatra application
    class App < Sinatra::Application
      configure do
        set sessions: true,
            secure: production?,
            expire_after: 31_557_600,
            secret: ENV['SESSION_SECRET']
      end

      use Rack::Deflater
      use Rack::Session::Cookie
      use Rack::Csrf, raise: true,
                      skip: ['POST:/login',
                             'POST:/unauthenticated']

      helpers Helpers

      register Sinatra::Flash

      # Configure Warden to authenticate
      use Warden::Manager do |config|
        config.serialize_into_session(&:username)
        config.serialize_from_session do |username|
          # Animal skins & flint knives...
          token = env['rack.request.cookie_hash']['cyclid.token']
          Models::User.get(username: username, token: token)
        end

        config.scope_defaults :default,
                              strategies: [:session],
                              action: '/unauthenticated'

        config.failure_app = self
      end

      Warden::Strategies.add(:session) do
        def valid?
          session.key? :username
        end

        def authenticate!
          username = session[:username]
          # There are no Helpers in Wardentown
          token = request.cookies['cyclid.token']

          user = Models::User.get(username: username, token: token)

          user.nil? ? fail!('invalid user') : success!(user)
        end
      end

      Warden::Manager.before_failure do |env, _opts|
        env['REQUEST_METHOD'] = 'POST'
      end

      post '/unauthenticated' do
        # Stop Warden from calling this endpoint again in an endless loop when
        # it sees the 401 response
        env['warden'].custom_failure!
        flash[:login_error] = 'Invalid username or password'
        redirect to '/login'
      end

      # Register the other routes
      use Controllers::Auth
      use Controllers::Organization
      use Controllers::User
      use Controllers::Health
      use Controllers::Default
    end
  end
end
