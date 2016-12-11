# frozen_string_literal: true
require 'spec_helper'

describe Cyclid::UI::Controllers::Organization do
  include Rack::Test::Methods

  let :user do
    u = double('user')
    allow(u).to receive(:username).and_return('test')
    allow(u).to receive(:email).and_return('test@example.com')
    allow(u).to receive(:organizations).and_return(%w(a b))
    allow(u).to receive(:to_hash).and_return('mocked object')
    return u
  end

  let :klass do
    class_double(Cyclid::UI::Models::User).as_stubbed_const
  end

  before :each do
    allow(klass).to receive(:get).and_return(user)

    cfg = instance_double(Cyclid::UI::Config)
    allow(cfg).to receive_message_chain('client_api.inspect').and_return('mocked object')
    allow(cfg).to receive_message_chain('client_api.host').and_return('example.com')
    allow(cfg).to receive_message_chain('client_api.port').and_return(9999)
    allow(cfg).to receive('memcached').and_return('example.com:4242')
    allow(cfg).to receive('signup').and_return(nil)
    allow(Cyclid).to receive(:config).and_return(cfg)
  end

  describe '#get /:name' do
    it 'requires authentication' do
      get 'test'
      expect(last_response.status).to eq(302)
      expect(last_response['Location']).to eq 'http://example.org/login'
    end

    it 'returns an organization page' do
      set_cookie 'cyclid.token=token'

      get '/test', {}, 'rack.session' => { 'username' => 'test' }
      expect(last_response.status).to eq(200)
    end
  end

  describe '#get /:name/job/:id' do
    it 'requires authentication' do
      get 'test/job/9999'
      expect(last_response.status).to eq(302)
      expect(last_response['Location']).to eq 'http://example.org/login'
    end

    it 'returns a job page' do
      set_cookie 'cyclid.token=token'

      get '/test/job/9999', {}, 'rack.session' => { 'username' => 'test' }
      expect(last_response.status).to eq(200)
    end
  end
end
