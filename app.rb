require 'require_all'
require 'logger'
require 'warden'
require 'memcached'
require 'sinatra/flash'

require_rel 'app/config'
require_rel 'app/memcache'
require_rel 'app/helpers'

require_all 'app/models'
require_all 'app/controllers'

require_rel 'app/views/layout'

module Cyclid
  class << self
    attr_accessor :config, :logger

    config_path = ENV['CYCLID_MANAGE_CONFIG'] || File.join(%w(/ etc cyclid manage))
    Cyclid.config = UI::Config.new(config_path)

    begin
      Cyclid.logger = if Cyclid.config.log.casecmp('stderr').zero?
                        Logger.new(STDERR)
                      else
                        Logger.new(Cyclid.config.log)
                      end
    rescue StandardError => ex
      abort "Failed to initialize: #{ex}"
    end
  end
end

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
      use Rack::Csrf, raise: true,
                      skip: ['POST:/login',
                             'POST:/unauthenticated']

      helpers Helpers

      register Sinatra::Flash

      # Configure Warden to authenticate
      use Warden::Manager do |config|
        config.serialize_into_session(&:username)
        config.serialize_from_session do |username|
          # Animal skins & flint knives...
          token = env['rack.request.cookie_hash']['cyclid.token']
          Models::User.get(username: username, token: token)
        end

        config.scope_defaults :default,
                              strategies: [:session],
                              action: '/unauthenticated'

        config.failure_app = self
      end

      Warden::Strategies.add(:session) do
        def valid?
          session.has_key? :username
        end

        def authenticate!
          username = session[:username]
          # There are no Helpers in Wardentown
          token = request.cookies['cyclid.token']

          user = Models::User.get(username: username, token: token)

          user.nil? ? fail!('invalid user') : success!(user)
        end
      end

      Warden::Manager.before_failure do |env, _opts|
        env['REQUEST_METHOD'] = 'POST'
      end

      post '/unauthenticated' do
        # Stop Warden from calling this endpoint again in an endless loop when
        # it sees the 401 response
        env['warden'].custom_failure!
        flash[:login_error] = 'Invalid username or password'
        redirect to '/login'
      end

      # Register the other routes
      use Controllers::Auth
      use Controllers::Organization
      use Controllers::User
    end
  end
end
