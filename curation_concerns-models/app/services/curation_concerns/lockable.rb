module CurationConcerns
  module Lockable
    extend ActiveSupport::Concern

    def acquire_lock_for(lock_key, &block)
      lock_manager.lock(lock_key, &block)
    end

    def lock_manager
      @lock_manager ||= CurationConcerns::LockManager.new(
        CurationConcerns.config.lock_time_to_live,
        CurationConcerns.config.lock_retry_count,
        CurationConcerns.config.lock_retry_delay)
    end
  end
end
