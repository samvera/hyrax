require 'wings/active_fedora_converter'
require 'wings/resources/file_metadata'
require 'wings/services/file_converter_service'

module Wings
  module Pcdm
    module ObjectValkyrieBehavior
      extend ActiveSupport::Concern

      included do
        include Wings::Pcdm::PcdmValkyrieBehavior
        attribute :file_metadata, ::Valkyrie::Types::Set.of(::FileMetadata.optional)
      end

      ##
      # @return [Boolean] whether this instance is a PCDM Object.
      def pcdm_object?
        true
      end

      ##
      # @return [Boolean] whether this instance is a PCDM Collection.
      def pcdm_collection?
        false
      end

      ##
      # Finds or Initializes directly contained file with the requested RDF Type
      #
      # @param [RDF::URI] uri for the desired Type
      # @return [ActiveFedora::File]
      #
      # @example
      #   file_of_type(::RDF::URI("http://pcdm.org/ExtractedText"))
      def file_of_type(uri, valkyrie: false)
        af_object = Wings::ActiveFedoraConverter.new(resource: self).convert
        file = af_object.file_of_type(uri)
        return file unless file.new_record?
        Wings::FileConverterService.convert_and_add_file_to_resource(file, self)
        file
      end

      # TODO: Add translated methods
    end
  end
end
