module Hyrax
  class ImportUrlFailureService < AbstractMessageService
    def message
      file_set.errors.full_messages.join(', ')
    end

    def subject
      'File Import Error'
    end
  end
end
