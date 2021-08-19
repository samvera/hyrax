# frozen_string_literal: true
module Hyrax
  module Admin
    class DashboardPresenter
      # @return [Fixnum] the number of currently registered users
      def user_count
        ::User.where(guest: false).count
      end

      def repository_objects
        @repository_objects ||= Admin::RepositoryObjectPresenter.new
      end

      def repository_growth
        @repository_growth ||= Admin::RepositoryGrowthPresenter.new
      end

      def user_activity(start_date, end_date)
        @user_activity ||= Admin::UserActivityPresenter.new(start_date, end_date)
      end
    end
  end
end
