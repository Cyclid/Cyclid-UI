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

require 'oj'

module Cyclid
  module UI
    # Various helper methods for Sinatra controllers
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

      # Safely parse & validate the request body
      def parse_request_body
        # Parse the the request
        begin
          request.body.rewind

          if request.content_type == 'application/json' or \
             request.content_type == 'text/json'

            data = Oj.load request.body.read
          else
            halt(415, "unsupported content type #{request.content_type}")
          end
        rescue Oj::ParseError, YAML::Exception => ex
          Cyclid.logger.debug ex.message
          halt(400, ex.message)
        end

        # Sanity check the request
        halt(400, 'request body can not be empty') if data.nil?
        halt(400, 'request body is invalid') unless data.is_a?(Hash)

        return data
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
    end
  end
end
