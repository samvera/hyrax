module Sufia
  class ImportUrlFailureService < MessageUserService
    def message
      generic_file.errors.full_messages.join(', ')
    end

    def subject
      'File Import Error'
    end
  end
end
