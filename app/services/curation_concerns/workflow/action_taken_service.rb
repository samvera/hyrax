module CurationConcerns
  module Workflow
    # Responsible for performing additional functions when the given criteria is met.
    class ActionTakenService
      # For the given :entity and :action
      # - Find the appropriate "function" to call
      # - Then call that function
      def self.handle_action_taken(entity:, action:, comment:, user:)
        new(entity: entity,
            action: action,
            comment: comment,
            user: user).call
      end

      def initialize(entity:, action:, comment:, user:)
        @entity = entity
        @action = action
        @comment = comment
        @user = user
      end

      attr_reader :action, :entity, :comment, :user

      def call
        action.triggered_methods.order(:weight).each do |method|
          process_action(method.service_name)
        end
      end

      def process_action(service_name)
        service = resolve_service(service_name)
        return unless service
        service.call(entity: entity,
                     comment: comment,
                     user: user)
      end

      def resolve_service(service_name)
        class_name = service_name.classify
        klass = begin
                  class_name.constantize
                rescue NameError
                  Rails.logger.error "Unable to find '#{class_name}', so not running workflow callback"
                  return nil
                end
        return klass if klass.respond_to?(:call)
        Rails.logger.error "Expected '#{class_name}' to respond to 'call', but it didn't, so not running workflow callback"
        nil
      end
    end
  end
end
