module Sufia
  class ImportLocalFileSuccessService < MessageUserService
    attr_reader :filename

    def initialize(generic_file, user, filename)
      @filename = filename
      super(generic_file, user)
    end

    def call
      CurationConcerns.queue.push(ContentDepositEventJob.new(generic_file.id, user.user_key))
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
