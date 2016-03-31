module Sufia
  class ImportUrlSuccessService < MessageUserService
    def call
      ContentDepositEventJob.perform_later(file_set, user)
      super
    end

    def message
      "The file (#{file_set.label}) was successfully imported."
    end

    def subject
      'File Import'
    end
  end
end
