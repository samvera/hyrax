module Hyrax
  class ImportUrlFailureService < AbstractMessageService
    def message
      "There was a problem importing from #{file_set.import_url}"
    end

    def subject
      'File Import Error'
    end
  end
end
