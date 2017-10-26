module Hyrax
  module Workflow
    # @abstract A notification that happens when a state transition occurs. Subclass AbstractNotification to create a notification.
    # @example
    #   module Hyrax
    #     module Workflow
    #       class LocalApprovedNotification < AbstractNotification
    #         private
    #
    #           def subject
    #             "Deposit #{title} has been approved"
    #           end
    #
    #           def message
    #             "#{title} (#{link_to work_id, document_path}) has been approved by #{user.display_name}  #{comment}"
    #           end
    #
    #           # Add the user who initiated this action to the list of users being notified
    #           def users_to_notify
    #             super << user
    #           end
    #       end
    #     end
    #   end
    class AbstractNotification
      include ActionView::Helpers::UrlHelper

      def self.send_notification(entity:, comment:, user:, recipients:)
        new(entity, comment, user, recipients).call
      end

      attr_reader :work_id, :title, :comment, :user, :recipients

      # @param [Sipity::Entity] entity - the Sipity::Entity that is a proxy for the relevant Hyrax work
      # @param [#comment] comment - the comment associated with the action being taken, could be a Sipity::Comment, or anything that responds to a #comment method
      # @param [Hyrax::User] user - the user who has performed the relevant action
      # @param [Hash] recipients - a hash with keys "to" and (optionally) "cc"
      # @option recipients [Array<Hyrax::User>] :to a list of users to which to send the notification
      # @option recipients [Array<Hyrax::User>] :cc a list of users to which to copy on the notification
      def initialize(entity, comment, user, recipients)
        @work_id = entity.proxy_for_global_id.sub(/.*\//, '')
        @title = entity.proxy_for.title.first
        @comment = comment.respond_to?(:comment) ? comment.comment.to_s : ''
        # Convert to hash with indifferent access to allow both string and symbol keys
        @recipients = recipients.with_indifferent_access
        @user = user
        @entity = entity
      end

      def call
        users_to_notify.uniq.each do |recipient|
          Hyrax::MessengerService.deliver(user, recipient, message, subject)
        end
      end

      private

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

        def users_to_notify
          recipients.fetch(:to, []) + recipients.fetch(:cc, [])
        end
    end
  end
end
