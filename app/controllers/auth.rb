require 'json'

module Cyclid
  module UI
    module Controllers
      class Auth < Base
        get '/login' do
          mustache :login, locals: env
        end

        post '/login' do
          username = params[:username]
          password = params[:password]
          STDERR.puts "#{username} logged in with password #{password}"

          # Get the CSRF token from Rack; it'll be added to the JWT claims
          csrf_token = Rack::Csrf.csrf_token(env)

          # Use the username & password to authenticate against the API; if
          # successful, it will return a JWT that can be used to authenticate
          # future requests
          token_data = token_get(username, password, csrf_token)
          STDERR.puts token_data

          # At this point the user has autenticated successfully; get the user
          # information; the User model will cache it automatically.
          # XXX We need someway to do this with an authenticated API request;
          # either HTTP Basic (as we have the username & password in this
          # method) or the JWT.
          user_data = User.get(username: username).to_hash
          STDERR.puts user_data

          # Store the username in the session
          session[:username] = username

          # Return the JWT cookie to the client as a cookie
          response.set_cookie('cyclid.token',
                              value: token_data['token'],
                              expires: Time.now + 21600000,   # +6 hours
                              path: '/',
                              http_only: false) # Must be available for AJAX

          # XXX Hook into a Warden strategy

          # Return a "login success" page along with the JWT & CSRF as cookie
          # data, so that they can be stored; the page should then do redirect
          # to the main page
          mustache :login_success
        end

        helpers Helpers
      end
    end
  end
end
