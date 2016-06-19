module Cyclid
  module UI
    module Controllers
      class Organization < Base
        get '/organizations' do
          authenticate!

          @current_user = current_user

          mustache :organizations
        end
      end
    end
  end
end
