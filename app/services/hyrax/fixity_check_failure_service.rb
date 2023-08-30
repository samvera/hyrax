# frozen_string_literal: true
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
      uri = checksum_audit_log.checked_uri
      file_title = file_set.title.first
      I18n.t('hyrax.notifications.fixity_check_failure.message', log_date: log_date, file_title: file_title, uri: uri)
    end

    def subject
      I18n.t('hyrax.notifications.fixity_check_failure.subject')
    end
  end
end
