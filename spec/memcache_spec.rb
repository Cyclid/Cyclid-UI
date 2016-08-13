# frozen_string_literal: true
require 'spec_helper'

describe Cyclid::UI::Memcache do
  let :klass do
    class_double('Memcached').as_stubbed_const(transfer_nested_constants: true)
  end

  let :memcache do
    instance_double('Memcached')
  end

  describe '#initialize' do
    context 'with a default expiry time' do
      it 'creates a new memcache' do
        args = { server: 'example.com' }

        allow(klass).to receive(:new).with(args[:server]).and_return(memcache)

        m = nil
        expect{ m = Cyclid::UI::Memcache.new(args) }.to_not raise_error

        expect(m.server).to eq(args[:server])
        expect(m.expiry).to eq(3600)
      end
    end

    context 'with a non-default expiry time' do
      it 'creates a new memcache' do
        args = { server: 'example.com', expiry: 9999 }

        allow(klass).to receive(:new).with(args[:server]).and_return(memcache)

        m = nil
        expect{ m = Cyclid::UI::Memcache.new(args) }.to_not raise_error

        expect(m.server).to eq(args[:server])
        expect(m.expiry).to eq(args[:expiry])
      end
    end
  end

  context 'instance methods' do
    let :args do
      { server: 'example.com' }
    end

    before :each do
      allow(klass).to receive(:new).with(args[:server]).and_return(memcache)
    end

    subject { Cyclid::UI::Memcache.new(args) }

    describe '#cache' do
      it 'returns a cached object' do
        allow(memcache).to receive(:get).with('cached').and_return('cached object')

        expect(subject.cache('cached')).to eq 'cached object'
      end

      it 'yields the block for an uncached object' do
        allow(memcache).to receive(:get).with('uncached').and_raise(Memcached::NotFound)
        allow(memcache).to receive(:set).with('uncached', nil, 3600)

        expect{ |b| subject.cache('uncached', &b) }.to yield_with_no_args
      end
    end

    describe '#expire' do
      context 'with a cached object' do
        it 'expires an object' do
          allow(memcache).to receive(:delete).with('valid').and_return(true)

          expect(subject.expire('valid')).to be true
        end
      end

      context 'without a cached object' do
        it 'expires an object' do
          allow(memcache).to receive(:delete).with('invalid').and_raise(Memcached::NotFound)

          expect(subject.expire('invalid')).to be false
        end
      end
    end
  end
end
