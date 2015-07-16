module Sufia
  class ImportUrlSuccessService < MessageUserService
    def call
      CurationConcerns.queue.push(ContentDepositEventJob.new(generic_file.id, user.user_key))
      super
    end

    def message
      "The file (#{generic_file.label}) was successfully imported."
    end

    def subject
      'File Import'
    end
  end
end
