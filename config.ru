# encoding: utf-8
# frozen_string_literal: true
#
# Copyright 2016 Liqwyd Ltd
#
# Authors: Kristian Van Der Vliet <vanders@liqwyd.com>
require 'sinatra'

require 'cyclid_ui/app'

configure :production do
  map '/' do
    app = Cyclid::UI::App
    app.set :bind, '0.0.0.0'
    app.set :port, 80
    app.run!
  end
end

configure :development do
  map '/' do
    run Cyclid::UI::App
  end
end
