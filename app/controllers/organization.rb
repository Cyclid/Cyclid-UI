module Cyclid
  module UI
    module Controllers
      class Organization < Base
        get '/:name' do
          authenticate!

          # Build breadcrumbs
          name = params[:name]

          @crumbs = []
          @crumbs << {'name' => name.capitalize}

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
          @crumbs << {'url' => "/#{name}", 'name' => name.capitalize}
          @crumbs << {'name' => "Job ##{id}"}

          @organization = name
          @linkback_url = "/#{name}"

          api_server = 'http://localhost:8092'
          @job_url = "#{api_server}/organizations/#{params[:name]}/jobs/#{params[:id]}"
          @current_user = current_user

          mustache :job
        end

      end
    end
  end
end
