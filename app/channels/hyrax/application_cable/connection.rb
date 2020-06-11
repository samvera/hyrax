# frozen_string_literal: true
module Hyrax
  module ApplicationCable
    class Connection < ActionCable::Connection::Base
      identified_by :current_user

      def connect
        self.current_user = find_verified_user
      end

      private

      def find_verified_user
        user = ::User.find_by(id: user_id)
        if user
          user
        else
          reject_unauthorized_connection
        end
      end

      def user_id
        session['warden.user.user.key'][0][0]
      rescue NoMethodError
        nil
      end

      def session
        cookies.encrypted[Rails.application.config.session_options[:key]]
      end
    end
  end
end
