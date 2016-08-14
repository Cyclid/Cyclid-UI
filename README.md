Cyclid-UI
=========
This is the web based user interface to the Cyclid CI server.

# Getting started
```
$ rbenv install 2.3.0
$ bundle install --path vendor/bundle
```
Cyclid-UI can optionally use Memcached for storing some user object data; if you choose to run a Memcached server on your local machine Cyclid-UI will connect by default on `localhost:11211`.

Cyclid-UI requires a Cyclid API server that both it and the client (I.e. the web browser) can connect too. See the documentation for the Cyclid API server for information on how to install & configure Cyclid.

You can start Cyclid-UI under Webrick with `bundle exec rake rackup` or you can run under Guard with `bundle exec rake guard`.

# Testing

RSpec tests are included. Run `bundle exec rake spec` to run the tests and generate a coverage report into the `coverage` directory. The tests do not affect any databases and external API calls are mocked.

The Cyclid-UI source code is also expected to pass Rubocop; run `bundle exec rake rubocop` to lint the code.