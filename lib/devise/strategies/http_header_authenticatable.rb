# Copyright © 2012 The Pennsylvania State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Default strategy for signing in a user, based on his email and password in the database.
module Devise
  module Strategies
    class HttpHeaderAuthenticatable < ::Devise::Strategies::Base

      # Called if the user doesn't already have a rails session cookie
      def valid?
        request.headers['REMOTE_USER'].present?
      end

      def authenticate!
        remote_user = request.headers['REMOTE_USER']
        if remote_user.present?
          u = User.find_by_login(remote_user)
          if u.nil?
            u = User.create(:login => remote_user)
            u.populate_attributes
          end
          success!(u)
        else
          fail!
        end
      end
    end
  end
end

Warden::Strategies.add(:http_header_authenticatable, Devise::Strategies::HttpHeaderAuthenticatable)

