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
  end
end
