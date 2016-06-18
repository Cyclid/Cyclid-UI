# encoding: utf-8

begin
  require 'bundler/setup'
end

task :rackup do
  system 'rackup'
end

task :guard do
  system 'guard'
end

task :default do
  Rake::Task['rackup'].invoke
end
