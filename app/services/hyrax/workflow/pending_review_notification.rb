module Hyrax
  module Workflow
    class PendingReviewNotification < AbstractNotification
      private

        def subject
          I18n.t('hyrax.notifications.workflow.pending_review.subject')
        end

        def message
          I18n.t('hyrax.notifications.workflow.pending_review.message', title: title,
                                                                        link: (link_to work_id, document_path),
                                                                        user: user.user_key, comment: comment)
        end

        def users_to_notify
          super << user
        end
    end
  end
end
