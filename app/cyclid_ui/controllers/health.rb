# frozen_string_literal: true
# Copyright 2016 Liqwyd Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
require 'sinatra/cross_origin'
require 'sinatra-health-check'
require 'memcached'

# Top level module for all of the core Cyclid code.
module Cyclid
  module UI
    module Controllers
      # Controller for all Health related API endpoints
      class Health < Base
        register Sinatra::CrossOrigin

        def initialize(_app)
          super
          @checker = SinatraHealthCheck::Checker.new(logger: Cyclid.logger,
                                                     timeout: 0)

          # Add internal health checks
          @checker.systems[:memcache] = Cyclid::UI::Health::Memcache
          @checker.systems[:api] = Cyclid::UI::Health::API
        end

        # Return either 200 (healthy) or 503 (unhealthy) based on the status of
        # the healthchecks. This is intended to be used by things like load
        # balancers and active monitors.
        get '/health/status' do
          cross_origin
          @checker.healthy? ? 200 : 503
        end

        # Return verbose information on the status of the individual checks;
        # note that this method always returns 200 with a message body, so it is
        # not suitable for general health checks unless the caller intends to
        # parse the message body for the health status.
        get '/health/info' do
          cross_origin
          @checker.status.to_json
        end
      end
    end

    # Healthchecks
    module Health
      # Internal Memcache connection health check
      module Memcache
        # Check if Memcache is available
        def self.status
          connected = begin
                        memcache = Memcached.new(Cyclid.config.memcached)
                        memcache.stats
                        true
                      rescue Memcached::SomeErrorsWereReported
                        false
                      end

          if connected
            SinatraHealthCheck::Status.new(:ok, 'memcache connection is okay')
          else
            SinatraHealthCheck::Status.new(:warning, 'memcache is not available')
          end
        end
      end

      # Internal API connection health check
      module API
        # Check if we can connect to the Cyclid API
        def self.status
          connected = begin
                        client = Client::Tilapia.new(auth: Client::AUTH_NONE,
                                                     log_level: Logger::DEBUG,
                                                     server: Cyclid.config.server_api.host,
                                                     port: Cyclid.config.server_api.port)
                        client.health_ping
                      rescue
                        false
                      end

          if connected
            SinatraHealthCheck::Status.new(:ok, 'API connection is okay')
          else
            SinatraHealthCheck::Status.new(:error, 'API is not available')
          end
        end
      end
    end
  end
end
