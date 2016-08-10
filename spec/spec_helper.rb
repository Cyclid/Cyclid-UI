require 'bundler/setup'
require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
  add_filter '/public/'

  add_group 'Controllers', 'app/controllers'
  add_group 'Views', 'app/views'
  add_group 'Models', 'app/models'
end

# Configure RSpec
RSpec::Expectations.configuration.warn_about_potential_false_positives = false

# Pull in the Rack mocks
require 'rack/test'

ENV['RACK_ENV'] = 'test'

# Required by the Rack mocks
def app
  Cyclid::UI::App
end

# Pull in the code
require 'sinatra'
require 'rack/csrf'

require_relative '../app'
