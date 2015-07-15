module Sufia
  class AuditFailureService < MessageUserService
    attr_reader :log_date

    def initialize(generic_file, user, log_date)
      @log_date = log_date
      super(generic_file, user)
    end

    def message
      uri = generic_file.original_file.uri.to_s
      file_title = generic_file.title.first
      "The audit run at #{log_date} for #{file_title} (#{uri}) failed."
    end

    def subject
      'Failing Audit Run'
    end
  end
end
