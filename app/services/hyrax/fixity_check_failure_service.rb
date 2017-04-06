module Hyrax
  class FixityCheckFailureService < MessageUserService
    attr_reader :log_date

    def initialize(file_set, user, log_date)
      @log_date = log_date
      super(file_set, user)
    end

    def message
      uri = file_set.original_file.uri.to_s
      file_title = file_set.title.first
      "The fixity check run at #{log_date} for #{file_title} (#{uri}) failed."
    end

    def subject
      'Failing Fixity Check'
    end
  end
end
