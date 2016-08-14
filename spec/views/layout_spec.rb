# frozen_string_literal: true
require 'spec_helper'

describe Cyclid::UI::Views::Layout do
  let :user do
    u = double('user')
    allow(u).to receive(:username).and_return('test')
    allow(u).to receive(:email).and_return('test@example.com')
    allow(u).to receive(:organizations).and_return(%w(a b))
    return u
  end

  subject do
    l = Cyclid::UI::Views::Layout.new
    l.instance_variable_set(:@current_user, user)
    return l
  end

  describe '#username' do
    context 'when the username is set' do
      it 'returns the username' do
        expect(subject.username).to eq 'test'
      end
    end

    context 'when the username is not set' do
      it 'returns a placeholder' do
        # Over-ride the normal username
        allow(user).to receive(:username).and_return(nil)

        expect(subject.username).to eq 'Nobody'
      end
    end
  end

  describe '#organizations' do
    it 'returns the users organizations' do
      expect(subject.organizations).to eq %w(a b)
    end
  end

  describe '#title' do
    context 'with a title set' do
      it 'returns the title' do
        subject.instance_variable_set(:@title, 'test')
        expect(subject.title).to eq('test')
      end
    end

    context 'without a title set' do
      it 'returns the default title' do
        expect(subject.title).to eq('Cyclid')
      end
    end
  end

  describe '#breadcrumbs' do
    it 'returns the breadcrumbs as JSON' do
      subject.instance_variable_set(:@crumbs, foo: 'bar')
      expect(subject.breadcrumbs).to eq('{"foo":"bar"}')
    end
  end

  describe 'gravatar_url' do
    it 'returns a valid Gravatar URL' do
      expect(subject.gravatar_url).to eq('https://www.gravatar.com/avatar/55502f40dc8b7c769880b10874abc9d0?d=identicon&r=g')
    end
  end
end
