module CurationConcerns
  class TimeService
    def self.time_in_utc
      DateTime.now.utc
    end
  end
end
