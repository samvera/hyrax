# frozen_string_literal: true
require 'redlock'
module Hyrax
  class LockManager
    class UnableToAcquireLockError < StandardError; end

    attr_reader :client

    # @param [Fixnum] time_to_live How long to hold the lock in milliseconds
    # @param [Fixnum] retry_count How many times to retry to acquire the lock before raising UnableToAcquireLockError
    # @param [Fixnum] retry_delay Maximum wait time in milliseconds before retrying. Wait time is a random value between 0 and retry_delay.
    def initialize(time_to_live, retry_count, retry_delay)
      @ttl = time_to_live
      @client = Redlock::Client.new([(Hyrax.config.redis_connection || Redis.current)], retry_count: retry_count, retry_delay: retry_delay)
    end

    # Blocks until lock is acquired or timeout.
    def lock(key)
      returned_from_block = nil
      client.lock(key, @ttl) do |locked|
        raise UnableToAcquireLockError unless locked
        returned_from_block = yield
      end
      returned_from_block
    end
  end
end
