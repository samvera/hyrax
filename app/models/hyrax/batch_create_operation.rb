# frozen_string_literal: true
module Hyrax
  class BatchCreateOperation < Operation
    set_callback :success, :after, :batch_success_message
    set_callback :failure, :after, :batch_failure_message

    def batch_success_message
      return unless Hyrax.config.callback.set?(:after_batch_create_success)
      Hyrax.config.callback.run(:after_batch_create_success, user, warn: false)
    end

    def batch_failure_message
      return unless Hyrax.config.callback.set?(:after_batch_create_failure)
      Hyrax.config.callback.run(:after_batch_create_failure, user, rollup_messages, warn: false)
    end
  end
end
