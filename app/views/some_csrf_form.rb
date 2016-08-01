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

# CSRF view for forms which POST back to this server. This is not currently
# used.
class SomeCSRFForm < Mustache
  def csrf_tag
    # @env is a local, passed as:
    #
    # mustache :somecsrfform, locals: env
    Rack::Csrf.csrf_tag(@env)
  end

  # Or alternatively:
  include Cyclid::UI::Helpers

  def csrf
    csrf_tag(@env)
  end
end
