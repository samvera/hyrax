module Hyrax
  class BatchCreateOperation < Operation
    set_callback :success, :after, :batch_success_message
    set_callback :failure, :after, :batch_failure_message

    def batch_success_message
      return unless Hyrax.config.callback.set?(:after_batch_create_success)
      Hyrax.config.callback.run(:after_batch_create_success, user)
    end

    def batch_failure_message
      return unless Hyrax.config.callback.set?(:after_batch_create_failure)
      Hyrax.config.callback.run(:after_batch_create_failure, user)
    end
  end
end
