module Cyclid
  module UI
    module Controllers
      class Organization < Base
        get '/organizations' do
          authenticate!

          @current_user = current_user

          mustache :organizations
        end

        get '/organizations/:org' do
          authenticate!

          # Get the organization data from the API
          begin
            token = cookies['cyclid.token']
            client = Client::Tilapia.new(auth: Client::AUTH_TOKEN,
                                         server: 'localhost',
                                         port: 8092,
                                         username: current_user.username,
                                         token: token)

            @org = client.org_get(params[:org])
          rescue Exception => ex
            STDERR.puts "something went wrong: #{ex}"
            halt 500, 'i have fallen and i can not get up'
          end

          @current_user = current_user

          mustache :organization
        end
      end
    end
  end
end
