module Sufia
  class BatchCreateOperation < CurationConcerns::Operation
    set_callback :success, :after, :batch_success_message
    set_callback :failure, :after, :batch_failure_message

    def batch_success_message
      return unless Sufia.config.callback.set?(:after_batch_create_success)
      Sufia.config.callback.run(:after_batch_create_success, user)
    end

    def batch_failure_message
      return unless Sufia.config.callback.set?(:after_batch_create_failure)
      Sufia.config.callback.run(:after_batch_create_failure, user)
    end
  end
end
