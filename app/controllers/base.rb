require 'sinatra/base'
require 'sinatra/cookies'
require 'sinatra/flash'
require 'mustache'
require 'mustache/sinatra'

module Cyclid
  module UI
    module Controllers
      class Base < Sinatra::Base
        register Mustache::Sinatra

        set :mustache, {
          templates: File.expand_path('../../templates/', __FILE__),

          views: File.expand_path('../../views/', __FILE__),

          namespace: Cyclid::UI
        }

        register Sinatra::Flash

        helpers Sinatra::Cookies, AuthHelpers
      end
    end
  end
end
