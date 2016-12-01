module Sufia
  module Lockable
    extend ActiveSupport::Concern

    def acquire_lock_for(lock_key, &block)
      lock_manager.lock(lock_key, &block)
    end

    def lock_manager
      @lock_manager ||= LockManager.new(
        Sufia.config.lock_time_to_live,
        Sufia.config.lock_retry_count,
        Sufia.config.lock_retry_delay
      )
    end
  end
end
