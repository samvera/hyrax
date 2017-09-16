module Hyrax
  class FixityCheckFailureService < AbstractMessageService
    attr_reader :log_date, :checksum_audit_log, :file_set

    def initialize(file_set, checksum_audit_log:)
      @file_set = file_set
      @checksum_audit_log = checksum_audit_log
      @log_date = checksum_audit_log.created_at

      user = ::User.find_by_user_key(file_set.depositor)

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
