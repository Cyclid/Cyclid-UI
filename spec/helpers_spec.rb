require 'spec_helper'

describe Cyclid::UI::Helpers do
  include Rack::Test::Methods

  subject { Class.new { extend Cyclid::UI::Helpers } }

  describe '#csrf_token' do
    it 'returns a CSRF token' do
      env = Rack::MockRequest.env_for('http://example.com/test', {'rack.session' => {'username' => 'test'}})
      expect{subject.csrf_token(env)}.to_not raise_error
    end
  end

  describe '#csrf_tag' do
    it 'returns a CSRF tag' do
      env = Rack::MockRequest.env_for('http://example.com/test', {'rack.session' => {'username' => 'test'}})
      expect{subject.csrf_tag(env)}.to_not raise_error
    end
  end

  describe '#halt_with_401' do
    it 'returns an HTTP 401 response' do
      flash = double('flash')
      expect(flash).to receive(:[]=).with(:login_error, 'Invalid username or password')
      expect(flash).to receive(:now).and_return({login_error: nil})

      expect(subject).to receive(:flash).twice.and_return(flash)
      expect(subject).to receive(:halt).with(401, nil).and_return(401)

      res = nil
      expect{res = subject.halt_with_401}.to_not raise_error
      expect(res).to eq(401)
    end
  end
end
