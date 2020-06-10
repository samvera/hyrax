# frozen_string_literal: true
module Hyrax
  module Lockable
    extend ActiveSupport::Concern

    def acquire_lock_for(lock_key, &block)
      lock_manager.lock(lock_key, &block)
    end

    def lock_manager
      @lock_manager ||= LockManager.new(
        Hyrax.config.lock_time_to_live,
        Hyrax.config.lock_retry_count,
        Hyrax.config.lock_retry_delay
      )
    end
  end
end
