# frozen_string_literal: true
require 'spec_helper'

describe Cyclid::UI::Controllers::User do
  include Rack::Test::Methods

  let :user do
    u = double('user')
    allow(u).to receive(:username).and_return('test')
    allow(u).to receive(:email).and_return('test@example.com')
    allow(u).to receive(:organizations).and_return(%w(a b))
    return u
  end

  let :klass do
    class_double(Cyclid::UI::Models::User).as_stubbed_const
  end

  before :each do
    allow(klass).to receive(:get).and_return(user)

    cfg = instance_double(Cyclid::UI::Config)
    allow(cfg).to receive_message_chain('server_api.inspect').and_return('mocked object')
    allow(cfg).to receive_message_chain('server_api.host').and_return('example.com')
    allow(cfg).to receive_message_chain('server_api.port').and_return(9999)
    allow(cfg).to receive_message_chain('client_api.inspect').and_return('mocked object')
    allow(cfg).to receive_message_chain('client_api.host').and_return('example.com')
    allow(cfg).to receive_message_chain('client_api.port').and_return(9999)
    allow(cfg).to receive_message_chain('memcached').and_return('example.com:4242')
    allow(Cyclid).to receive(:config).and_return(cfg)
  end

  before :all do
    clear_cookies
  end

  describe '#get /user/:username' do
    it 'requires authentication' do
      get '/user/test'
      expect(last_response.status).to eq(302)
      expect(last_response['Location']).to eq 'http://example.org/login'
    end

    it 'return a valid user' do
      set_cookie 'cyclid.token=token'

      get '/user/test', {}, 'rack.session' => { 'username' => 'test' }
      expect(last_response.status).to eq(200)
    end
  end
end
