module Cyclid
  module UI
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
      # If we have to fall back to the API we currently assume that the HTTP
      # Basic username & password are available and valid.
      def self.get(args)
        username = args[:username] || args['username']
        memcache = Memcache.new(server: 'localhost:11211') 

        user_data = memcache.cache username do
                      user_get(args)
                    end
        self.new(user_data)
      end

      def self.user_get(args)
        username = args[:username] || args['username']
        password = args[:password] || args['password']

        user_data = nil
        begin
          client = Client::Tilapia.new(auth: Client::AUTH_BASIC,
                                       server: 'localhost',
                                       port: 8092,
                                       username: username,
                                       password: password)
          user_data = client.user_get(username)
          STDERR.puts "got #{user_data}"
        rescue Exception => ex
          STDERR.puts "failed to get user details: #{ex}"
          raise ex
        end

        user_data
      end
    end
  end
end
