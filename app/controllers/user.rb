module Cyclid
  module UI
    module Controllers
      class User < Base
        get '/user/:username' do
          authenticate!

          # Build breadcrumbs
          username = params[:username]

          @crumbs = []
          @crumbs << {'name' => 'User'}
          @crumbs << {'url' => "/user/#{username}", 'name' => username}

          @api_url = 'http://localhost:8092'
          @user_url = "#{@api_url}/users/#{params[:username]}"
          @current_user = current_user

          mustache :user
        end
      end
    end
  end
end
