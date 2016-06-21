module Cyclid
  module UI
    module Helpers
      def csrf_token(rack_env)
        Rack::Csrf.csrf_token(rack_env)
      end

      def csrf_tag(rack_env)
        Rack::Csrf.csrf_tag(rack_env)
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
