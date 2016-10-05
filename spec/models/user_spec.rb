# frozen_string_literal: true
require 'spec_helper'

describe Cyclid::UI::Models::User do
  let :user do
    { 'username' => 'test',
      'email' => 'test@example.com',
      'organizations' => %w(a b),
      'id' => 99 }
  end

  context 'with no arguments' do
    it 'creates a new instance' do
      u = nil
      expect{ u = Cyclid::UI::Models::User.new }.to_not raise_error

      expect(u.username).to eq nil
      expect(u.email).to eq nil
      expect(u.organizations).to eq []
      expect(u.id).to eq nil
    end
  end

  context 'with arguments' do
    it 'creates a new instance' do
      args = { 'username' => 'test',
               'email' => 'test@example.com',
               'organizations' => %w(a b),
               'id' => 99 }

      u = nil
      expect{ u = Cyclid::UI::Models::User.new(args) }.to_not raise_error

      expect(u.username).to eq args['username']
      expect(u.email).to eq args['email']
      expect(u.organizations).to eq args['organizations']
      expect(u.id).to eq args['id']
    end
  end

  context 'instance methods' do
    let :args do
      { 'username' => 'test',
        'email' => 'test@example.com',
        'name' => nil,
        'organizations' => %w(a b),
        'id' => 99 }
    end

    subject { Cyclid::UI::Models::User.new(args) }

    describe '#to_hash' do
      it 'returns a valid hash' do
        expect(subject.to_hash).to be_an_instance_of(Hash)
        expect(subject.to_hash).to eq args
      end
    end
  end

  context 'with memcached' do
    describe '#get' do
      let :klass do
        class_double('Cyclid::UI::Memcache').as_stubbed_const
      end

      let :memcache do
        instance_double('Cyclid::UI::Memcache')
      end

      before :each do
        allow(klass).to receive(:new).and_return(memcache)
      end

      it 'returns an object that is in the cache' do
        allow(memcache).to receive(:cache).with('test').and_return(user)

        u = nil
        expect{ u = Cyclid::UI::Models::User.get(user) }.to_not raise_error
        expect(u).to be_an_instance_of(Cyclid::UI::Models::User)
        expect(u.username).to eq user['username']
        expect(u.email).to eq user['email']
        expect(u.organizations).to eq user['organizations']
        expect(u.id).to eq user['id']
      end

      it 'returns an object that is not in the cache' do
        allow(memcache).to receive(:cache).with('test'){ user }

        u = nil
        expect{ u = Cyclid::UI::Models::User.get(user) }.to_not raise_error
        expect(u).to be_an_instance_of(Cyclid::UI::Models::User)
        expect(u.username).to eq user['username']
        expect(u.email).to eq user['email']
        expect(u.organizations).to eq user['organizations']
        expect(u.id).to eq user['id']
      end

      it 'falls back to an API call when Memcache is not available' do
        allow(memcache).to receive(:cache).with('test').and_raise(Memcached::ServerIsMarkedDead)
        allow(Cyclid::UI::Models::User).to receive(:user_fetch).and_return(user)

        u = nil
        expect{ u = Cyclid::UI::Models::User.get(user) }.to_not raise_error
        expect(u).to be_an_instance_of(Cyclid::UI::Models::User)
        expect(u.username).to eq user['username']
        expect(u.email).to eq user['email']
        expect(u.organizations).to eq user['organizations']
        expect(u.id).to eq user['id']
      end
    end
  end

  context 'without memcached' do
    describe '#user_fetch' do
      let :klass do
        class_double('Cyclid::Client::Tilapia').as_stubbed_const
      end

      let :client do
        instance_double('Cyclid::Client::Tilapia')
      end

      before :each do
        allow(klass).to receive(:new).and_return(client)

        cfg = instance_double(Cyclid::UI::Config)
        allow(cfg).to receive_message_chain('server_api.inspect').and_return('mocked object')
        allow(cfg).to receive_message_chain('server_api.host').and_return('example.com')
        allow(cfg).to receive_message_chain('server_api.port').and_return(9999)
        allow(Cyclid).to receive(:config).and_return(cfg)
      end

      it 'uses HTTP Basic auth when no API token is given' do
        args = { username: 'test',
                 password: 'password' }

        expect(klass).to receive(:new).with(auth: Cyclid::Client::AUTH_BASIC,
                                            server: 'example.com',
                                            port: 9999,
                                            username: args[:username],
                                            password: args[:password],
                                            token: nil).and_return(client)

        allow(client).to receive(:user_get).with(args[:username]).and_return(user)

        u = nil
        expect{ u = Cyclid::UI::Models::User.user_fetch(args) }.to_not raise_error
        expect(u).to be_an_instance_of(Hash)
        expect(u).to eq user
      end

      it 'uses API Token auth when an token is given' do
        args = { username: 'test',
                 token: 'token' }

        expect(klass).to receive(:new).with(auth: Cyclid::Client::AUTH_TOKEN,
                                            server: 'example.com',
                                            port: 9999,
                                            username: args[:username],
                                            password: nil,
                                            token: args[:token]).and_return(client)

        allow(client).to receive(:user_get).with(args[:username]).and_return(user)

        u = nil
        expect{ u = Cyclid::UI::Models::User.user_fetch(args) }.to_not raise_error
        expect(u).to be_an_instance_of(Hash)
        expect(u).to eq user
      end

      it 'fails gracefully when the API call fails' do
        args = { username: 'test',
                 token: 'token' }

        expect(klass).to receive(:new).with(auth: Cyclid::Client::AUTH_TOKEN,
                                            server: 'example.com',
                                            port: 9999,
                                            username: args[:username],
                                            password: nil,
                                            token: args[:token]).and_return(client)

        allow(client).to receive(:user_get).with(args[:username]).and_raise(StandardError)

        u = nil
        expect{ u = Cyclid::UI::Models::User.user_fetch(args) }.to raise_error
      end
    end
  end
end
