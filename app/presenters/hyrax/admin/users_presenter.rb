module Hyrax
  module Admin
    class UsersPresenter
      # @return [Array] an array of Users
      def users
        @users ||= search
      end

      # @return [Number] quantity of users excluding the system users and guest_users
      def user_count
        users.count
      end

      # @return [Array] an array of user roles
      def user_roles(user)
        user.groups
      end

      def last_accessed(user)
        user.last_sign_in_at || user.created_at
      end

      protected

        # Returns a list of users excluding the system users and guest_users
        def search
          ::User.registered.without_system_accounts
        end
    end
  end
end
