module Hyrax
  class ImportUrlSuccessService < MessageUserService
    def call
      FileSetAttachedEventJob.perform_later(file_set, user)
      super
    end

    def message
      "The file (#{file_set.label}) was successfully imported and attached to #{curation_concern.title.first}."
    end

    def subject
      'File Import'
    end

    private

      def curation_concern
        file_set.in_works.first
      end
  end
end
