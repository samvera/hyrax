# frozen_string_literal: true
require 'redlock'
module Hyrax
  class LockManager
    class UnableToAcquireLockError < StandardError; end

    ##
    # @param [Fixnum] time_to_live How long to hold the lock in milliseconds
    # @param [Fixnum] retry_count How many times to retry to acquire the lock before raising UnableToAcquireLockError
    # @param [Fixnum] retry_delay Maximum wait time in milliseconds before retrying. Wait time is a random value between 0 and retry_delay.
    def initialize(time_to_live, retry_count, retry_delay)
      @ttl = time_to_live
      @retry_count = retry_count
      @retry_delay = retry_delay
    end

    ##
    # Blocks until lock is acquired or timeout.
    def lock(key, ttl: @ttl, retry_count: @retry_count, retry_delay: @retry_delay)
      returned_from_block = nil

      pool.then do |conn|
        client(conn, retry_count: retry_count, retry_delay: retry_delay).lock(key, ttl) do |locked|
          raise UnableToAcquireLockError unless locked
          returned_from_block = yield
        end
      end

      returned_from_block
    rescue ConnectionPool::TimeoutError => err
      Hyrax.logger.error(err.message)
      raise(ConnectionPool::TimeoutError,
            "Failed to acquire a lock from Redlock due to a Redis connection " \
              "timeout: #{err}. If you are using Redis via `ConnectionPool` " \
              "you may wish to increase the pool size.")
    end

    private

    ##
    # @api_private
    def client(conn, retry_count:, retry_delay:)
      Redlock::Client.new([conn], retry_count: retry_count, retry_delay: retry_delay)
    end

    ##
    # @api private
    #
    # @note support both a ConnectionPool and a raw Redis client for now.
    #   `#then` supports both options. for a ConnectionPool it will block
    #   until a connection is available.
    def pool
      Hyrax.config.redis_connection || Redis.new
    end
  end
end
