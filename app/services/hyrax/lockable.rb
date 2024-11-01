# frozen_string_literal: true
require 'forwardable'

module Hyrax
  module Lockable
    extend Forwardable
    extend ActiveSupport::Concern

    def_delegator :lock_manager, :lock, :acquire_lock_for

    def lock_manager
      @lock_manager ||= LockManager.new(
        Hyrax.config.lock_time_to_live,
        Hyrax.config.lock_retry_count,
        Hyrax.config.lock_retry_delay
      )
    end
  end
end
