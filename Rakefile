# encoding: utf-8

begin
  require 'bundler/setup'
end

ENV['CYCLID_MANAGE_CONFIG'] = File.join(%w(config development))

task :rackup => :memcached do
  system 'rackup'
end

task :guard => :memcached do
  system 'guard'
end

task :memcached do
  system 'memcached -d'
end

task :default do
  Rake::Task['rackup'].invoke
end
