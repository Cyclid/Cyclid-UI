# frozen_string_literal: true
require 'spec_helper'
require 'json'

describe 'a health check' do
  include Rack::Test::Methods

  context 'when the application is healthy' do
    before do
      allow_any_instance_of(SinatraHealthCheck::Checker).to receive(:healthy?).and_return true
    end

    describe 'GET /health/status' do
      it 'returns a 200 response' do
        get '/health/status'
        expect(last_response.status).to eq(200)
      end
    end

    describe 'GET /health/info' do
      it 'returns a JSON response' do
        get '/health/info'
        expect(last_response.status).to eq(200)

        res = JSON.parse(last_response.body)
        expect(res['status']).to eq 'OK'
      end
    end
  end

  context 'when the application is unhealthy' do
    before do
      allow_any_instance_of(SinatraHealthCheck::Checker).to receive(:healthy?).and_return false
    end

    describe 'GET /health/status' do
      it 'returns a 503 response' do
        get '/health/status'
        expect(last_response.status).to eq(503)
      end
    end

    describe 'GET /health/info' do
      it 'returns a JSON response' do
        dbl = double('memcache')
        allow(dbl).to receive(:stats).and_raise Memcached::SomeErrorsWereReported

        allow(Memcached).to receive(:new).and_return dbl

        get '/health/info'
        expect(last_response.status).to eq(200)

        res = JSON.parse(last_response.body)
        STDERR.puts "res=#{res.inspect}"
        expect(res['status']).to eq 'WARNING'
      end
    end
  end
end

describe Cyclid::UI::Health::Memcache do
  describe '#status' do
    let :memcache do
      double('memcache')
    end

    before do
      allow(Memcached).to receive(:new).and_return memcache
    end

    it 'returns an OK response when memcache is connected' do
      allow(memcache).to receive(:stats).and_return(true)

      expect(status = Cyclid::UI::Health::Memcache.status).to be_a(SinatraHealthCheck::Status)
      expect(status.level).to eq(:ok)
      expect(status.message).to eq('memcache connection is okay')
    end

    it 'returns an error response when memcache is not connected' do
      allow(memcache).to receive(:stats).and_raise Memcached::SomeErrorsWereReported

      expect(status = Cyclid::UI::Health::Memcache.status).to be_a(SinatraHealthCheck::Status)
      expect(status.level).to eq(:warning)
      expect(status.message).to eq('memcache is not available')
    end
  end
end

describe Cyclid::UI::Health::API do
  describe '#status' do
    let :tilapia do
      double('tilapia')
    end

    before do
      allow(Cyclid::Client::Tilapia).to receive(:new).and_return tilapia
    end

    it 'returns an OK response when the API is connected' do
      allow(tilapia).to receive(:health_ping).and_return true

      expect(status = Cyclid::UI::Health::API.status).to be_a(SinatraHealthCheck::Status)
      expect(status.level).to eq(:ok)
      expect(status.message).to eq('API connection is okay')
    end

    it 'returns an error response when the API is not connected' do
      allow(tilapia).to receive(:health_ping).and_return false

      expect(status = Cyclid::UI::Health::API.status).to be_a(SinatraHealthCheck::Status)
      expect(status.level).to eq(:error)
      expect(status.message).to eq('API is not available')
    end
  end
end
