# frozen_string_literal: true

module Wings
  class ActiveFedoraConverter
    ##
    # Constructs an instance for the given converter. +converter+ must provide
    # an +id+, +resource+, and +active_fedora_class+.
    #
    # This interface allows handling for special cases based on the target
    # class, instance data for +resource+, or the id format. This originated as
    # an extraction of some such special handling from the converter code.
    class InstanceBuilder
      ##
      # @!attribute [r] converter
      #   @return [#active_fedora_class, #id, #resource]
      # @!attribute [r] resource
      #   @return [Valkyrie::Resource]
      attr_reader :converter, :resource

      ##
      # @param [#active_fedora_class, #id, #resource]
      def initialize(converter)
        @converter = converter
        @resource = converter.resource
      end

      ##
      # @return [ActiveFedora::Common]
      def build
        if builds_file_metadata? && !builds_metadata_for_active_fedora_file?
          # convert to a generic/generated FileMetadataNode class with
          # properties matching the source class
          Wings::ActiveFedoraConverter::FileMetadataNode(resource.class)
                                      .new(file_identifier: Array(resource.file_identifier)
            .map(&:to_s))
        elsif converter.id.present?
          converter.active_fedora_class.find(converter.id)
        else
          converter.active_fedora_class.new
        end
      rescue ActiveFedora::ObjectNotFoundError
        converter.active_fedora_class.new
      end

      ##
      # @return [Boolean]
      def builds_file_metadata?
        resource.try(:file_identifier).present?
      end

      ##
      # @return [Boolean]
      def builds_metadata_for_active_fedora_file?
        return false unless builds_file_metadata?

        adapter_for_file = begin
                             ::Valkyrie::StorageAdapter.adapter_for(id: resource.file_identifier)
                           rescue ::Valkyrie::StorageAdapter::AdapterNotFoundError => err
                             Hyrax.logger.warn "Processing a FileMetadata (id: #{converter.id}) referencing " \
                                               "a file #{resource.file_identifier}; could not find a " \
                                               "storage adapter to handle that file.\n\t#{err.message}"
                           end

        adapter_for_file.is_a?(::Valkyrie::Storage::Fedora)
      end
    end
  end
end
