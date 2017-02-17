module Hyrax
  class AdminDashboardPresenter
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
  end
end
