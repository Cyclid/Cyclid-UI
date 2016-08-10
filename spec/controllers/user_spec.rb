require 'spec_helper'

describe Cyclid::UI::Controllers::User do
  include Rack::Test::Methods

  let :user do
    u = double('user')
    allow(u).to receive(:username).and_return('test')
    allow(u).to receive(:email).and_return('test@example.com')
    allow(u).to receive(:organizations).and_return(['a','b'])
    return u
  end

  let :klass do
    class_double(Cyclid::UI::Models::User).as_stubbed_const
  end

  before :each do
    allow(klass).to receive(:get).and_return(user)
  end

  before :all do
    clear_cookies
  end

  describe '#/user/:username' do
    it 'requires authentication' do
      get '/user/test'
      expect(last_response.status).to eq(302)
    end

    it 'return a valid user' do
      set_cookie 'cyclid.token=token'

      get '/user/test', {}, {'rack.session' => {'username' => 'test'}}
      expect(last_response.status).to eq(200)
    end
  end
end
