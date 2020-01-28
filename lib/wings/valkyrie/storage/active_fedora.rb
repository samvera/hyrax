require 'wings/hydra/works/services/add_file_to_file_set'

# frozen_string_literal: true
module Wings::Storage
  # Implements the DataMapper Pattern to store binary data in fedora following the ActiveFedora structures
  class ActiveFedora < Valkyrie::Storage::Fedora
    # @param file [Wings::FileMetadataBuilder::IoDecorator]
    # @param original_filename [String]
    # @param resource [Hyrax::FileMetadata] FileMetadata resource
    # @param resource_uri_transformer [Proc] transforms the resource's id (e.g. 'DDS78RK') into a uri (optional)
    # @param extra_arguments [Hash] additional arguments which may be passed to other adapters
    # @return [Valkyrie::StorageAdapter::StreamFile]
    def upload(file:, original_filename:, resource:, resource_uri_transformer: default_resource_uri_transformer, **_extra_arguments) # rubocop:disable Lint/UnusedMethodArgument
      Wings::Works::AddFileToFileSet.call(file_set: file_set(resource), file: file, type: resource.type)
      identifier = resource_uri_transformer.call(resource, base_url)
      find_by(id: Valkyrie::ID.new(identifier.to_s.sub(/^.+\/\//, PROTOCOL)))
    end

    private

      def file_set(file_metadata)
        file_set_id = file_metadata.file_set_id
        Hyrax.query_service.find_by(id: file_set_id)
      end
  end
end
