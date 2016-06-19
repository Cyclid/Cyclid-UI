module Cyclid
  module UI
    module Controllers
      class Organization < Base
        get '/organizations' do
          authenticate!

          mustache :organizations, locals: current_user
        end
      end
    end
  end
end
