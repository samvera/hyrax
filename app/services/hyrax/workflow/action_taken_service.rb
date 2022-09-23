# frozen_string_literal: true
module Hyrax
  module Workflow
    # Responsible for performing additional functions when the given criteria is met.
    class ActionTakenService
      # For the given target and :action
      # - Find the appropriate "function" to call
      # - Then call that function. If the function returns a truthy value, then save the target
      def self.handle_action_taken(target:, action:, comment:, user:)
        new(target: target,
            action: action,
            comment: comment,
            user: user).call
      end

      def initialize(target:, action:, comment:, user:)
        @target =
          case target
          when Valkyrie::Resource
            Hyrax::ChangeSet.for(target)
          else
            target
          end

        @action = action
        @comment = comment
        @user = user
      end

      attr_reader :action, :target, :comment, :user

      # Calls all the workflow methods for this action. Stops calling methods if any return falsy
      # @return [Boolean] true if all methods returned a truthy result
      def call
        return unless action.triggered_methods.any?
        success = action.triggered_methods.order(:weight).all? do |method|
          status = process_action(method.service_name)
          Hyrax.logger.debug("Result of #{method.service_name} is #{status}")
          status
        end

        return save_target if success
        Hyrax.logger.error "Not all workflow methods were successful, so not saving (#{target.id})"
        false
      end

      # @param service_name [String] the fully qualified class name to run the `call` method on
      # @yieldparam status the result of calling the method
      # @return the result of calling the method
      def process_action(service_name)
        service = resolve_service(service_name)
        return unless service
        result = service.call(target: target,
                              comment: comment,
                              user: user)
        yield(result) if block_given?
        result
      end

      # @param class_name [String] the fully qualified class name to run
      # @return [Class, NilClass] return nil if unable to locate the class
      def resolve_service(class_name)
        klass = begin
                  class_name.constantize
                rescue NameError
                  Hyrax.logger.error "Unable to find '#{class_name}', so not running workflow callback"
                  return nil
                end
        return klass if klass.respond_to?(:call)
        Hyrax.logger.error "Expected '#{class_name}' to respond to 'call', but it didn't, so not running workflow callback"
        nil
      end

      private

      ##
      # @api private
      def save_target
        case target
        when Valkyrie::ChangeSet
          return target.model unless target.changed?

          Hyrax::Transactions::Container['change_set.apply']
            .with_step_args('change_set.save' => { user: user })
            .call(target)
            .value!
        else
          target.save
        end
      end
    end
  end
end
