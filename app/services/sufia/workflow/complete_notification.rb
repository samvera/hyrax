module Sufia
  module Workflow
    class CompleteNotification < AbstractNotification
      protected

        def subject
          'Deposit has been approved'
        end

        def message
          "#{title} (#{work_id}) was approved by #{user.user_key}. #{comment}"
        end

      private

        def users_to_notify
          user_key = ActiveFedora::Base.find(work_id).depositor
          super << ::User.find_by(email: user_key)
        end
    end
  end
end
