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
      # Controller for Organization related endpoints (including Jobs)
      class Organization < Base
        get '/:name' do
          authenticate!

          # Build breadcrumbs
          name = params[:name]

          @crumbs = []
          @crumbs << { 'name' => name.capitalize }

          @organization = name
          @linkback_url = "/#{name}"

          api_server = 'http://localhost:8092'
          @organization_url = "#{api_server}/organizations/#{params[:name]}"
          @current_user = current_user

          mustache :organization
        end

        get '/:name/job/:id' do
          authenticate!

          # Build breadcrumbs
          name = params[:name]
          id = params[:id]

          @crumbs = []
          @crumbs << { 'url' => "/#{name}", 'name' => name.capitalize }
          @crumbs << { 'name' => "Job ##{id}" }

          @organization = name
          @linkback_url = "/#{name}"

          api_server = 'http://localhost:8092'
          @job_url = "#{api_server}/organizations/#{params[:name]}/jobs/#{params[:id]}"
          @job_id = id
          @current_user = current_user

          mustache :job
        end
      end
    end
  end
end
