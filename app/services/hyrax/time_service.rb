# frozen_string_literal: true
module Hyrax
  class TimeService
    # @return [DateTime] the current time in UTC
    def self.time_in_utc
      DateTime.current
    end
  end
end
