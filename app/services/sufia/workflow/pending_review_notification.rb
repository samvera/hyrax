module Sufia
  module Workflow
    class PendingReviewNotification < AbstractNotification
      protected

        def subject
          'Deposit needs review'
        end

        def message
          "#{title} (#{work_id}) was deposited by #{user.user_key} and is awaiting approval #{comment}"
        end

      private

        def users_to_notify
          super << user
        end
    end
  end
end
