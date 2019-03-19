# Converson service for going between files on a valkyrie resource and files on an active fedora object
module Wings
  class FileConverterService
    class << self
      ##
      # Builds a `Valkyrie::Resource` equivalent for any files attached to the `pcdm_object`
      #
      # @return [Array<::Valkyrie::Resource>] resources mirroring files attached to `pcdm_object`
      def convert_and_add_file_to_resource(af_file, resource)
        attrs = af_file_attributes(af_file)
        file_metadata = resource.file_metadata.dup
        file_metadata << FileMetadata.new(**attrs)
        resource.file_metadata = file_metadata
      end

      def convert_and_add_file_to_af_object(file_metadata, af_object)
        return unless file_metadata.file_identifiers.present?
        af_file = Hydra::PCDM::File.find(file_metadata.file_identifiers.first)
        attrs = file_metadata_attributes(file_metadata)
        attrs.each { |key, value| af_file.metadata_node.set_value(key, value) }
        af_object.files << af_file
      end

      private
        def af_file_attributes(af_file)
          attrs = af_file.metadata_node.attributes.keys.map(&:to_sym)
          attrs.each_with_object({}) do |attr_name, attr_hash|
            next unless af_file.metadata_node.respond_to? attr_name
            attr_hash[attr_name] = ValueMapper.for(af_file.metadata_node.public_send(attr_name)).result
          end
              .merge(file_identifiers: [af_file.id],
                     mime_type: ValueMapper.for(af_file.metadata_node.public_send(:mime_type)).result,
                     type: ValueMapper.for(af_file.metadata_node.public_send(:type)).result)
        end

        def file_metadata_attributes(file_metadata)
          attrs = file_metadata.attributes.dup
          attrs.delete(:file_identifiers)
          attrs.delete(:id)
          attrs.delete(:internal_resource)
          attrs.delete(:new_record)
          attrs.delete(:id)
          attrs.delete(:alternate_ids)
          attrs.delete(:created_at)
          attrs.delete(:updated_at)
          attrs.compact
        end
    end
  end
end
