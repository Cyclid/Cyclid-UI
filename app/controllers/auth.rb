require 'json'

module Cyclid
  module UI
    module Controllers
      class Auth < Base
        register Sinatra::Memcacher
        set :memcacher_enabled, true

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
          # information from the API and cache it.
          user_data = cache username do
                        user_get(username)
                      end
          STDERR.puts user_data

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

        private

        # XXX Testing; this is obviously something we should use Tilapia to do
        def token_get(username, password, csrf_token)
          token_data = nil
          api = URI('http://localhost:9393/token')
          Net::HTTP.start(api.host, api.port) do |http|
            request = Net::HTTP::Post.new api
            request.basic_auth(username, password)
            request.body = {csrf: csrf_token}.to_json

            response = http.request(request)
            token_data = JSON.parse(response.body)
          end
          token_data
        end

        def user_get(username)
          user_data = nil
          api = URI("http://localhost:9393/user/#{username}")
          Net::HTTP.start(api.host, api.port) do |http|
            request = Net::HTTP::Get.new api

            response = http.request(request)
            user_data = JSON.parse(response.body)
          end
          user_data
        end
      end
    end
  end
end
