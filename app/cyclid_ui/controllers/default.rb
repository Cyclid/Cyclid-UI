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
    module Controllers
      # Sinatra controller for default routes
      class Default < Base
        # Default route; redirect depending on the current session status
        get '/' do
          # Non-authenticated users will automatically redirect to the login page
          authenticate!

          # Authenticated users will redirect to one of two potential locations
          user = current_user

          # Pick the first organization from the users membership and
          # redirect; if the user doesn't belong to any organizations,
          # redirect them to their user page
          initial_page = if user.organizations.empty?
                           "/user/#{user.username}"
                         else
                           user.organizations.first
                         end

          redirect to initial_page
        end
      end
    end
  end
end
