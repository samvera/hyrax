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
        md = event[:metadata]

        Hyrax::Characterization::ValkyrieCharacterizationService.run(md, md.file)
        Hyrax.persister.save(resource: md)
        Hyrax.index_adapter.save(resource: event[:file_set])
      end
    end
  end
end
