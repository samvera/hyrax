# frozen_string_literal: true
module Hyrax
  ##
  # Events are timestamped, named actions that provide a streamed 'paper trail'
  # of certain repository activities.
  #
  # Not to be confused with the +Dry::Events+-based pub/sub interface at
  # {Hyrax::Publisher}.
  #
  # @see Hyrax::RedisEventStore
  class Event
    ##
    # Creates an event in Redis
    #
    # @note it's advisable to use {Hyrax::TimeService} for timestamps, or use the
    #   {.create_now} method provided
    #
    # @param [String] action
    # @param [Integer] timestamp
    def self.create(action, timestamp)
      store.create(action, timestamp)
    end

    ##
    # @return [#create]
    def self.store
      Hyrax::RedisEventStore
    end

    ##
    # Creates an event in Redis with a timestamp generated now
    #
    # @param [String] action
    #
    # @return [Event]
    def self.create_now(action)
      create(action, Hyrax::TimeService.time_in_utc.to_i)
    end
  end
end
