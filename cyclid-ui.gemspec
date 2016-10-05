# frozen_string_literal: true
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'cyclid_ui/version'

Gem::Specification.new do |s|
  s.name        = 'cyclid-ui'
  s.version     = Cyclid::UI::VERSION
  s.licenses    = ['Apache-2.0']
  s.summary     = 'Cyclid CI user interface'
  s.description = 'The Cyclid CI system'
  s.authors     = ['Kristian Van Der Vliet']
  s.homepage    = 'https://cyclid.io'
  s.email       = 'contact@cyclid.io'
  s.files       = Dir.glob('app/**/*') +
                  Dir.glob('lib/**/*') +
                  Dir.glob('public/**/*') +
                  Dir.glob('bin/*') +
                  %w(LICENSE README.md)
  s.bindir      = 'bin'
  s.executables << 'cyclid-ui-assets'

  s.add_runtime_dependency('require_all', '~> 1.3')
  s.add_runtime_dependency('sinatra', '~> 1.4')
  s.add_runtime_dependency('sinatra-contrib', '~> 1.4')
  s.add_runtime_dependency('rack_csrf', '~> 2.5')
  s.add_runtime_dependency('warden', '~> 1.2')
  s.add_runtime_dependency('activerecord', '~> 4.2')
  s.add_runtime_dependency('sinatra-activerecord', '~> 2.0')
  s.add_runtime_dependency('sinatra-health-check', '~> 0.2.0')
  s.add_runtime_dependency('sinatra-flash', '~> 0.3')
  s.add_runtime_dependency('mustache', '~> 1.0')
  s.add_runtime_dependency('mustache-sinatra', '~> 1.0')
  s.add_runtime_dependency('memcached', '~> 1.8')
  s.add_runtime_dependency('cyclid-client', '~> 0.3')
end
