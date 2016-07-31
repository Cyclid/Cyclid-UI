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
    module Helpers
      # Raw CSRF token
      def csrf_token(rack_env)
        Rack::Csrf.csrf_token(rack_env)
      end

      # CSRF HTML forms tag
      def csrf_tag(rack_env)
        Rack::Csrf.csrf_tag(rack_env)
      end

      # Standard unauthenticated 401 message
      def halt_with_401
        flash[:login_error] = 'Invalid username or password'
        halt 401, flash.now[:login_error]
      end

      # Return a pre-configured Tilapia client instance
      def client
        @tilapia ||= Client::Tilapia.new(auth: Client::AUTH_TOKEN,
                                         server: 'localhost',
                                         port: 8092,
                                         username: current_user.username,
                                         token: current_token)
      end
    end

    # Sinatra Warden AuthN/AuthZ helpers
    module AuthHelpers
      # Return the current Warden scope
      def warden
        env['warden']
      end

      # Call the Warden authenticate! method
      def authenticate!
        warden.authenticate!
      end

      # Current User object from the session
      def current_user
        warden.user
      end

      # Current API token from the cookie
      def current_token
        token = cookies['cyclid.token']

        halt_with_401 if token.nil?
        token
      end
    end
  end
end
