# TODO: This should live in Hyrax::AddFileMetadataToFileSet service and should work for all valkyrie adapters.
module Wings::Works
  class AddFileToFileSet
    class << self
      # Adds a file to the file_set
      # @param file_set [Valkyrie::Resource] adding file to this file set
      # @param [IO,File,Rack::Multipart::UploadedFile, #read] file the object that will be the contents.
      #   If file responds to :mime_type, :content_type, :original_name, or :original_filename, those will be called to provide metadata.
      # @param [RDF::URI or String] type URI for the RDF.type that identifies the file's role within the file_set
      # @param [Boolean] update_existing whether to update an existing file if there is one. When set to true, performs a create_or_update.
      #   When set to false, always creates a new file within file_set.files.
      # @param [Boolean] versioning whether to create new version entries (only applicable if +type+ corresponds to a versionable file)
      def call(file_set:, file:, type:, update_existing: true, versioning: true)
        raise ArgumentError, 'supplied object must be an instance of Valkyrie::Resource' unless file_set.is_a?(Valkyrie::Resource) && file_set.file_set?
        raise ArgumentError, 'supplied file must respond to read' unless file.respond_to? :read

        af_type = normalize_type(type)
        raise ArgumentError, "supplied type (#{type}) is not supported" if af_type.blank?

        af_file_set = Wings::ActiveFedoraConverter.new(resource: file_set).convert
        result = Hydra::Works::AddFileToFileSet.call(af_file_set, file, af_type, update_existing: update_existing, versioning: versioning)

        # TODO: model_transformer/file_converter_service should create FileMetadata and set ids and attributes
        result ? af_file_set.valkyrie_resource : false
      end

      private

      def normalize_type(original_type)
        type = original_type.is_a?(Array) && !original_type.size.zero? ? original_type.first : original_type
        association_type(type) || type_to_rdf_uri(type)
      end

      def association_type(type)
        return type if [:original_file, :extracted_text, :thumbnail].include? type
        type_to_association_type type
      end

      def type_to_association_type(type)
        case type
        when Hyrax::FileMetadata::Use::ORIGINAL_FILE
          :original_file
        when Hyrax::FileMetadata::Use::EXTRACTED_TEXT
          :extracted_text
        when Hyrax::FileMetadata::Use::THUMBNAIL
          :thumbnail
        end
      end

      def type_to_rdf_uri(type)
        return type if type.is_a? RDF::URI
        return RDF::URI.new(type) if type.is_a? String
      end
    end
  end
end
