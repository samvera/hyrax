module Sufia
  module Workflow
    class AbstractNotification
      def self.send_notification(entity:, comment:, user:, recipients:)
        new(entity, comment, user, recipients).call
      end

      attr_reader :work_id, :title, :comment, :user, :recipients

      def initialize(entity, comment, user, recipients)
        @work_id = entity.proxy_for_global_id.sub(/.*\//, '')
        @title = entity.proxy_for.title.first
        @comment = comment.respond_to?(:comment) ? comment.comment.to_s : ''
        @recipients = recipients
        @user = user
      end

      def call
        user.send_message(users_to_notify.uniq, message, subject)
      end

      protected

        def subject
          raise NotImplementedError, "Implement #subject in a child class"
        end

        def message
          "#{title} (#{work_id}) was advanced in the workflow by #{user.user_key} and is awaiting approval #{comment}"
        end

      private

        def users_to_notify
          recipients['to'] + recipients['cc']
        end
    end
  end
end
