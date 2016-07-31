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

require 'yaml'

module Cyclid
  module UI
    # Cyclid UI configuration
    class Config
      attr_reader :memcached, :log

      def initialize(path)
        # Try to load the configuration file. If it can't be loaded, we'll
        # fall back to defaults
        begin
          @config = YAML.load_file(path)
        rescue Errno::ENOENT
          @config = {}
        end
 
        @memcached = @config['memcached'] || 'localhost:11211'
        @log = @config['log'] || File.join(%w(/ var log cyclid))
      rescue StandardError => ex
        abort "Failed to load configuration file #{path}: #{ex}"
      end
    end
  end
end
