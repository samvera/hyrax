# Default strategy for signing in a user, based on his email and password in the database.
module Devise
  module Strategies
    class HttpHeaderAuthenticatable < ::Devise::Strategies::Base

      # Called if the user doesn't already have a rails session cookie
      def valid?
         request.headers["REMOTE_USER"].present?
      end

      def authenticate!
        if request.headers["REMOTE_USER"].present?
          u = User.find_or_create_by_login(request.headers["REMOTE_USER"])
          success!(u)
        else
          fail!
        end
      end
    end
  end
end

Warden::Strategies.add(:http_header_authenticatable, Devise::Strategies::HttpHeaderAuthenticatable)

