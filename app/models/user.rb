module Cyclid
  module UI
    module Models
      class User
        attr_reader :username, :email, :organizations, :id

        def initialize(args)
          @username = args['username'] || nil
          @email = args['email'] || nil
          @organizations = args['organizations'] || []
          @id = args['id'] || nil
        end

        def to_hash
          { 'username' => @username,
            'email' => @email,
            'organizations' => @organizations,
            'id' => @id }
        end

        # Try to find the user object in Memcached; if it does not exist,
        # fallback to the API. If the API returns the user data, it will be
        # cached into Memcache for future use.
        #
        # If we have to fall back to the API we assume that the username is
        # valid and either the HTTP Basic password or an API token are available
        # and valid.
        def self.get(args)
          username = args[:username] || args['username']
          memcache = Memcache.new(server: Cyclid.config.memcached)

          user_data = begin
                        memcache.cache username do
                          user_fetch(args)
                        end
                      rescue Memcached::ServerIsMarkedDead => ex
                        Cyclid.logger.fatal "cannot connect to memcached: #{ex}"
                        # Fall back to a direct API connection
                        user_fetch(args)
                      end

          self.new(user_data)
        end

        def self.user_fetch(args)
          username = args[:username] || args['username']
          password = args[:password] || args['password']
          token = args[:token] || args['token']

          auth_method = token.nil? ? Client::AUTH_BASIC : Client::AUTH_TOKEN

          user_data = nil
          begin
            client = Client::Tilapia.new(auth: auth_method,
                                         server: 'localhost',
                                         port: 8092,
                                         username: username,
                                         password: password,
                                         token: token)
            user_data = client.user_get(username)
            Cyclid.logger.debug "got #{user_data}"
          rescue Exception => ex
            Cyclid.logger.fatal "failed to get user details: #{ex}"
            raise ex
          end

          user_data
        end
      end
    end
  end
end
