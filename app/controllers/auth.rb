require 'json'

module Cyclid
  module UI
    module Controllers
      class Auth < Base
        get '/login' do
          mustache :login
        end

        post '/login' do
          username = params[:username]
          password = params[:password]
          STDERR.puts "#{username} logged in with password #{password}"

          # We really just need to use something like rack_csrf and get the
          # token its generated
          csrf_token = SecureRandom.uuid
          token_data = get_token(username, password, csrf_token)
          STDERR.puts token_data

          # user_get
          # XXX Hook into a Warden strategy
          # Store the userdata & JWT in memcached and store the memcached key
          # in the session

          # Return the JWT to the client
          response.set_cookie('cyclid.token',
                              value: token_data['jwt_token'],
                              expires: Time.now + 21600000,   # +6 hours
                              path: '/',
                              http_only: false) # Must be available for AJAX

          # Return a "login success" page along with the JWT & CSRF as cookie
          # data, so that they can be stored; the page should then do redirect
          # to the main page
          mustache :login_success
        end

        private

        # XXX Testing; this is obviously something we should use Tilapia to do
        def get_token(username, password, csrf_token)
          userdata = nil
          api = URI('http://localhost:9393/')
          Net::HTTP.start(api.host, api.port) do |http|
            request = Net::HTTP::Post.new api
            request.basic_auth(username, password)
            request.body = {csrf: csrf_token}.to_json

            response = http.request(request)
            userdata = JSON.parse(response.body)
          end
          userdata
        end
      end
    end
  end
end
