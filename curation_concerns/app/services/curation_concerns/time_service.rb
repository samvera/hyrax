module CurationConcerns
  class TimeService
    # @return [DateTime] the current time in UTC
    def self.time_in_utc
      DateTime.now.new_offset(0)
    end
  end
end
