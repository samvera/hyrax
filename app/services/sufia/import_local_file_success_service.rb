module Sufia
  class ImportLocalFileSuccessService < MessageUserService
    attr_reader :filename

    def initialize(file_set, user, filename)
      @filename = filename
      super(file_set, user)
    end

    def call
      ContentDepositEventJob.perform_later(file_set.id, user.user_key)
      super
    end

    def message
      "The file (#{File.basename(filename)}) was successfully deposited."
    end

    def subject
      'Local file ingest'
    end
  end
end
