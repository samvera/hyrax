# frozen_string_literal: true
module Hyrax
  ##
  # Give the current time in UTC
  #
  # Use of this service allows a single integration point timestamps. If your
  # application (or test suite) needs to provide a special time for "now", you
  # can override it here.
  #
  # @example
  #   Hyrax::TimeService.time_in_utc
  class TimeService
    ##
    # @return [DateTime] the current time in UTC
    def self.time_in_utc
      DateTime.current
    end
  end
end
