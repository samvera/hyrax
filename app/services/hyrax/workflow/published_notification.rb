# frozen_string_literal: true
module Hyrax
  module Workflow
    ##
    # Sent when a draft is promoted to active via the draft workflow's +activate+
    # action. Mirrors {DepositedNotification} but with "published" wording, since
    # in the draft lifecycle the transition is a publish, not an approval.
    class PublishedNotification < AbstractNotification
      private

      def subject
        I18n.t('hyrax.notifications.workflow.published.subject')
      end

      def message
        I18n.t('hyrax.notifications.workflow.published.message',
               title: title,
               link: (link_to work_id, document_path),
               user: user.user_key,
               comment: comment)
      end

      def users_to_notify
        user_key = @entity.proxy_for.depositor

        super << ::User.find_by_user_key(user_key)
      end
    end
  end
end
