module Cyclid
  module UI
    module Controllers
      class Organization < Base
        get '/organizations' do
          mustache :organizations
        end
      end
    end
  end
end
