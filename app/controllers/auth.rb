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

          # Get the CSRF token from Rack; it'll be added to the JWT claims
          csrf_token = Rack::Csrf.csrf_token(env)

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
            flash[:login_error] = 'Invalid username or password'
            halt 401, flash.now[:login_error]
          end

          # At this point the user has autenticated successfully; get the user
          # information; the User model will cache it automatically.
          # XXX We need someway to do this with an authenticated API request;
          # either HTTP Basic (as we have the username & password in this
          # method) or the JWT.
          user_data = User.get(username: username, password: password).to_hash
          STDERR.puts user_data

          # Store the username in the session
          session[:username] = username

          # Return the JWT cookie to the client as a cookie
          response.set_cookie('cyclid.token',
                              value: token_data['token'],
                              expires: Time.now + 21600000,   # +6 hours
                              path: '/',
                              http_only: false) # Must be available for AJAX

          # Return a "login success" page along with the JWT & CSRF as cookie
          # data, so that they can be stored; the page should then do redirect
          # to the main page
          mustache :login_success, layout: false
        end

        # Log out:
        #
        # 1. Delete the cached user object from Memcached
        # 2. Clear the session data
        # 3. Delete the API token cookie
        get '/logout' do
          memcache = Memcache.new(server: 'localhost:11211')
          memcache.expire(current_user.username)

          warden.logout
          cookies.delete 'cyclid.token'

          redirect to '/login'
        end

        helpers Helpers
      end
    end
  end
end
