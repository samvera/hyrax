module Sufia
  module Workflow
    class ChangesRequiredNotification < AbstractNotification
      protected

        def subject
          'Your deposit requires changes'
        end

        def message
          "#{title} (#{work_id}) requires additional changes before approval.\n\n '#{comment}'"
        end

      private

        def users_to_notify
          user_key = ActiveFedora::Base.find(work_id).depositor
          super << ::User.find_by(email: user_key)
        end
    end
  end
end
