require 'bundler/setup'
require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
  add_filter '/public/'
end

# Configure RSpec
RSpec::Expectations.configuration.warn_about_potential_false_positives = false

# Pull in the code
require 'sinatra'
require 'rack/csrf'

require_relative '../app'
