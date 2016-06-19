module Cyclid
  module UI
    module Helpers
      def csrf_token(rack_env)
        Rack::Csrf.csrf_token(rack_env)
      end

      def csrf_tag(rack_env)
        Rack::Csrf.csrf_tag(rack_env)
      end

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
    end

    # Sinatra Warden AuthN/AuthZ helpers
    module AuthHelpers
      # Return the current Warden scope
      def warden
        env['warden']
      end

      # Call the Warden authenticate! method
      def authenticate!
        warden.authenticate!
      end

      # Current User object from the session
      def current_user
        warden.user
      end
    end
  end
end
