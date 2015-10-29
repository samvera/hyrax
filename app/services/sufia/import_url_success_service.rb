module Sufia
  class ImportUrlSuccessService < MessageUserService
    def call
      CurationConcerns.queue.push(ContentDepositEventJob.new(file_set.id, user.user_key))
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
