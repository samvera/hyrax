module Sufia
  class AdminDashboardPresenter
    # @return [Fixnum] the number of currently registered users
    def user_count
      ::User.count
    end
  end
end
