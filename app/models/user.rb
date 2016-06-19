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

      # XXX Test method; should check Memcached & fallback to the API
      def self.get(args)
        username = args[:username] || args['username']
        memcache = Memcache.new(server: 'localhost:11211') 

        user_data = memcache.cache username do
                      user_get(username)
                    end
        self.new(user_data)
      end

      def self.user_get(username)
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
