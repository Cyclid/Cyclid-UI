# encoding: utf-8
# frozen_string_literal: true

begin
  require 'bundler/setup'
end

ENV['CYCLID_CONFIG'] = File.join(%w(config development))

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

begin
  require 'rubocop/rake_task'

  RuboCop::RakeTask.new
rescue LoadError
  task :rubocop do
    abort 'Rubocop is not available.'
  end
end

begin
  require 'yard'
rescue LoadError
  task :yard do
    abort 'YARD is not available.'
  end
end

task rackup: :memcached do
  system 'rackup'
end

task guard: :memcached do
  system 'guard'
end

task :memcached do
  system 'memcached -d'
end

task :default do
  Rake::Task['rackup'].invoke
end
