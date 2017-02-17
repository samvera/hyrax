module Hyrax
  class UsersPresenter
    attr_reader :query, :authentication_key

    def initialize(query:, authentication_key:)
      @query = query
      @authentication_key = authentication_key
    end

    # @return [Array] an array of Users
    def users
      @users = search(query)
    end

    def user_count
      ::User.registered.without_system_accounts.count
    end

    def repository_admin_count
      # require 'byebug'; debugger; true
      # count = 0
      # ::User.registered.without_system_accounts.each { |user| count += 1 if user.groups.include?('admin') }
      # count
    end

    def user_roles(user)
      require 'byebug'; debugger; true
      roles = user.groups
      return roles if roles.any?
      []
    end

    protected

      # Returns a list of users excluding the system users and guest_users
      # @param query [String] the query string
      def search(query)
        clause = query.blank? ? nil : "%" + query.downcase + "%"
        base = ::User.where(*base_query)
        unless clause.blank?
          base = base.where("#{authentication_key} like lower(?) OR display_name like lower(?)", clause, clause)
        end
        base.registered.without_system_accounts
      end

      # You can override base_query to return a list of arguments
      def base_query
        [nil]
      end
  end
end
