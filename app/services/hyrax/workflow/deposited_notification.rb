module Hyrax
  module Workflow
    class DepositedNotification < AbstractNotification
      private

        def subject
          I18n.t('hyrax.notifications.workflow.deposited.subject')
        end

        def message
          I18n.t('hyrax.notifications.workflow.deposited.message', title: title, link: (link_to work_id, document_path),
                                                                   user: user.user_key, comment: comment)
        end

        def users_to_notify
          user_key = ActiveFedora::Base.find(work_id).depositor
          super << ::User.find_by(email: user_key)
        end
    end
  end
end
