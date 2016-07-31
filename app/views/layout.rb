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

require 'digest/md5'

module Cyclid
  module UI
    module Views
      class Layout < Mustache
        attr_reader :organization, :api_url, :linkback_url

        def username
          @current_user.username || 'Nobody'
        end

        def organizations
          @current_user.organizations
        end

        def title
          @title || 'Cyclid'
        end

        # Return an array of elements to be inserted into the breadcrumb
        def breadcrumbs
          @crumbs.to_json
        end

        # Calculate the base Gravatar URL for the user
        def gravatar_url
          email = @current_user.email.downcase.strip
          hash = Digest::MD5.hexdigest(email)
          "https://www.gravatar.com/avatar/#{hash}?d=identicon&r=g"
        end
      end
    end
  end
end
