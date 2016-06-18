require 'require_all'

require_all 'app/controllers'

module Cyclid
  module UI
    class App < Sinatra::Application
      configure do
        set sessions: true,
            secure: production?,
            expire_after: 31557600,
            secret: ENV['SESSION_SECRET']
      end

      use Rack::Deflater
      use Rack::Session::Cookie

      use Controllers::Auth
      use Controllers::Organization
    end
  end
end
