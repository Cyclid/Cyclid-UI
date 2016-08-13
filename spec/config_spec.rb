require 'spec_helper'

describe Cyclid::UI::Config do
  let :empty_config do
    {'manage' => {}}
  end

  it 'loads a valid empty config' do
    expect(YAML).to receive(:load_file).with('/test/empty').and_return(empty_config)

    cfg = nil
    expect{ cfg = Cyclid::UI::Config.new('/test/empty') }.to_not raise_error
    expect( cfg.client_api.to_s ).to eq 'http://localhost:8361'
    expect( cfg.server_api.to_s ).to eq 'http://localhost:8361'
    expect( cfg.memcached ).to eq 'localhost:11211'
    expect( cfg.log ).to eq '/var/log/cyclid/manage'
  end

  let :simple_config do
    {'manage' => {
      'memcached' => 'example.com:1234',
      'log' => '/test/path',
      'api' => 'http://example.com/api'
    }}
  end

  it 'loads a valid simple config' do
    expect(YAML).to receive(:load_file).with('/test/simple').and_return(simple_config)

    cfg = nil
    expect{ cfg = Cyclid::UI::Config.new('/test/simple') }.to_not raise_error
    STDERR.puts "cfg=#{cfg.inspect}"
    expect( cfg.client_api.to_s ).to eq 'http://example.com/api'
    expect( cfg.server_api.to_s ).to eq 'http://example.com/api'
    expect( cfg.memcached ).to eq 'example.com:1234'
    expect( cfg.log ).to eq '/test/path'
  end

  let :complete_config do
    {'manage' => {
      'memcached' => 'example.com:1234',
      'log' => '/test/path',
      'api' => {
        'client' => 'http://example.com/client',
        'server' => 'http://example.com/server'
      }
    }}
  end

  it 'loads a valid complete config' do
    expect(YAML).to receive(:load_file).with('/test/complete').and_return(complete_config)

    cfg = nil
    expect{ cfg = Cyclid::UI::Config.new('/test/complete') }.to_not raise_error
    STDERR.puts "cfg=#{cfg.inspect}"
    expect( cfg.client_api.to_s ).to eq 'http://example.com/client'
    expect( cfg.server_api.to_s ).to eq 'http://example.com/server'
    expect( cfg.memcached ).to eq 'example.com:1234'
    expect( cfg.log ).to eq '/test/path'
  end

  it 'uses defaults if the config file can not be read' do
    expect(YAML).to receive(:load_file).with('/test/empty').and_raise(Errno::ENOENT)

    cfg = nil
    expect{ cfg = Cyclid::UI::Config.new('/test/empty') }.to_not raise_error
    expect( cfg.client_api.to_s ).to eq 'http://localhost:8361'
    expect( cfg.server_api.to_s ).to eq 'http://localhost:8361'
    expect( cfg.memcached ).to eq 'localhost:11211'
    expect( cfg.log ).to eq '/var/log/cyclid/manage'
  end
end 
