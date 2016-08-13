# frozen_string_literal: true
require 'spec_helper'

describe Cyclid::UI::Controllers::Auth do
  include Rack::Test::Methods

  let :user do
    u = double('user')
    allow(u).to receive(:username).and_return('test')
    allow(u).to receive(:email).and_return('test@example.com')
    allow(u).to receive(:organizations).and_return(%w(a b))
    allow(u).to receive(:to_hash).and_return('mocked object')
    return u
  end

  describe '#get /login' do
    it 'returns the login page' do
      get '/login'
      expect(last_response.status).to eq(200)
    end
  end

  describe '#post /login' do
    let :tilapia do
      class_double(Cyclid::Client::Tilapia).as_stubbed_const
    end

    let :client do
      instance_double(Cyclid::Client::Tilapia)
    end

    let :model do
      class_double(Cyclid::UI::Models::User).as_stubbed_const
    end

    before :each do
      cfg = instance_double(Cyclid::UI::Config)
      allow(cfg).to receive_message_chain('server_api.inspect').and_return('mocked object')
      allow(cfg).to receive_message_chain('server_api.host').and_return('example.com')
      allow(cfg).to receive_message_chain('server_api.port').and_return(9999)
      allow(cfg).to receive_message_chain('memcached').and_return('example.com:4242')
      allow(Cyclid).to receive(:config).and_return(cfg)
    end

    context 'with an invalid username & password' do
      it 'does not authenticate the user' do
        allow(tilapia).to receive(:new).with(auth: Cyclid::Client::AUTH_BASIC,
                                             log_level: Logger::DEBUG,
                                             server: 'example.com',
                                             port: 9999,
                                             username: 'test',
                                             password: 'password').and_raise(StandardError)

        post '/login', username: 'test', password: 'password'
        expect(last_response.status).to eq(302)
      end
    end

    context 'with a valid username & password' do
      context 'when the user belongs to organizations' do
        it 'authenticates the user' do
          allow(tilapia).to receive(:new).with(auth: Cyclid::Client::AUTH_BASIC,
                                               log_level: Logger::DEBUG,
                                               server: 'example.com',
                                               port: 9999,
                                               username: 'test',
                                               password: 'password').and_return(client)

          allow(client).to receive(:token_get).and_return('token')

          allow(model).to receive(:get).and_return(user)

          post '/login', username: 'test', password: 'password'
          expect(last_response.status).to eq(302)
          # Expect to be redirected back to the first organization; in the case
          # of the mocked user, that is 'a'. The mocked config sets the URL to
          # 'example.com', hence http://example.com/a
          expect(last_response['Location']).to eq 'http://example.org/a'
        end
      end

      context 'when the user does not belong to any organizations' do
        it 'authenticates the user' do
          allow(tilapia).to receive(:new).with(auth: Cyclid::Client::AUTH_BASIC,
                                               log_level: Logger::DEBUG,
                                               server: 'example.com',
                                               port: 9999,
                                               username: 'test',
                                               password: 'password').and_return(client)

          allow(client).to receive(:token_get).and_return('token')

          allow(model).to receive(:get).and_return(user)

          allow(user).to receive(:organizations).and_return([])

          post '/login', username: 'test', password: 'password'
          expect(last_response.status).to eq(302)
          # Expect to be redirected to the users profile. The mocked config
          # sets the URL to 'example.com', hence http://example.com/user/test
          expect(last_response['Location']).to eq 'http://example.org/user/test'
        end
      end
    end
  end

  describe '#get /logout' do
    let :klass do
      class_double('Cyclid::UI::Memcache').as_stubbed_const
    end

    let :memcache do
      instance_double('Cyclid::UI::Memcache')
    end

    let :model do
      class_double(Cyclid::UI::Models::User).as_stubbed_const
    end

    before :each do
      allow(model).to receive(:get).and_return(user)
    end

    before :all do
      clear_cookies
    end

    it 'requires authentication' do
      get '/logout'
      expect(last_response.status).to eq(302)
    end

    context 'with memcached' do
      it 'logs the user out' do
        set_cookie 'cyclid.token=token'

        allow(klass).to receive(:new).and_return(memcache)
        allow(memcache).to receive(:expire).and_return(true)

        get '/logout', {}, 'rack.session' => { 'username' => 'test' }
        expect(last_response.status).to eq(302)
        expect(last_response['Location']).to eq 'http://example.org/login'
      end
    end

    context 'without memcached' do
      it 'logs the user out' do
        set_cookie 'cyclid.token=token'

        allow(klass).to receive(:new).and_return(memcache)
        allow(memcache).to receive(:expire).and_raise(Memcached::ServerIsMarkedDead)

        get '/logout', {}, 'rack.session' => { 'username' => 'test' }
        expect(last_response.status).to eq(302)
        expect(last_response['Location']).to eq 'http://example.org/login'
      end
    end
  end
end
