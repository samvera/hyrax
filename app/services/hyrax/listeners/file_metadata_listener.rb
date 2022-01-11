# frozen_string_literal: true

module Hyrax
  module Listeners
    ##
    # Listens for events related to Hyrax::FileMetadata
    class FileMetadataListener
      ##
      # Called when 'object.file.uploaded' event is published
      # @param [Dry::Events::Event] event
      # @return [void]
      def on_object_file_uploaded(event)
        Hyrax::Characterization::ValkyrieCharacterizationService
          .run(metadata: event[:metadata], file: event[:metadata])
      end
    end
  end
end
