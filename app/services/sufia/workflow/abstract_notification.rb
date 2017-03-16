module Sufia
  module Workflow
    class AbstractNotification
      include ActionView::Helpers::UrlHelper

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
        @entity = entity
      end

      def call
        user.send_message(users_to_notify.uniq, message, subject)
      end

      protected

        def subject
          raise NotImplementedError, "Implement #subject in a child class"
        end

        def message
          "#{title} (#{link_to work_id, document_path}) was advanced in the workflow by #{user.user_key} and is awaiting approval #{comment}"
        end

        # @return [ActiveFedora::Base] the document (work) the the Abstract WorkFlow is creating a notification for
        def document
          @entity.proxy_for
        end

        def document_path
          key = document.model_name.singular_route_key
          Rails.application.routes.url_helpers.send(key + "_path", document.id)
        end

      private

        def users_to_notify
          recipients.fetch('to', []) + recipients.fetch('cc', [])
        end
    end
  end
end
