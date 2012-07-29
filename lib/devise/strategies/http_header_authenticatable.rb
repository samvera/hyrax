# Default strategy for signing in a user, based on his email and password in the database.
module Devise
  module Strategies
    class HttpHeaderAuthenticatable < ::Devise::Strategies::Base

      # Called if the user doesn't already have a rails session cookie
      def valid?
        request.headers["REMOTE_USER"].present?
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

