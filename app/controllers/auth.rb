require 'json'
require 'cyclid/client'

module Cyclid
  module UI
    module Controllers
      class Auth < Base
        get '/login' do
          @message = flash[:login_error]
          mustache :login, layout: false
        end

        post '/login' do
          username = params[:username]
          password = params[:password]

          # Use the username & password to authenticate against the API; if
          # successful, it will return a JWT that can be used to authenticate
          # future requests
          begin
            client = Client::Tilapia.new(auth: Client::AUTH_BASIC,
                                         log_level: Logger::DEBUG,
                                         server: 'localhost',
                                         port: 8092,
                                         username: username,
                                         password: password)
            token_data = client.token_get(username)
            STDERR.puts "got #{token_data}"
          rescue Exception => ex
            STDERR.puts "failed to get a token: #{ex}"
            halt_with_401
          end

          # At this point the user has autenticated successfully; get the user
          # information; the User model will cache it automatically.
          # XXX We need someway to do this with an authenticated API request;
          # either HTTP Basic (as we have the username & password in this
          # method) or the JWT.
          user = User.get(username: username, password: password)
          STDERR.puts user.to_hash

          # Store the username in the session
          session[:username] = username

          # Return the JWT cookie to the client as a cookie
          response.set_cookie('cyclid.token',
                              value: token_data['token'],
                              expires: Time.now + 21600000,   # +6 hours
                              path: '/',
                              http_only: false) # Must be available for AJAX

          # Pick the first organization from the users membership and redirect
          initial_org = user.organizations.first

          # XXX If the user does not belong to any organizations, direct to
          # their user page (once there is one)
          redirect to initial_org
        end

        # Log out:
        #
        # 1. Delete the cached user object from Memcached
        # 2. Clear the session data
        # 3. Delete the API token cookie
        get '/logout' do
          authenticate!

          memcache = Memcache.new(server: 'localhost:11211')
          memcache.expire(current_user.username)

          warden.logout
          cookies.delete 'cyclid.token'

          redirect to '/login'
        end
      end
    end
  end
end
