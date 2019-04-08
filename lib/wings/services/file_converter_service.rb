# Converson service for going between files on a valkyrie resource and files on an active fedora object
module Wings
  class FileConverterService
    class << self
      ##
      # Builds a `Valkyrie::Resource` equivalent for any files attached to the `pcdm_object`
      #
      # @return [Array<::Valkyrie::Resource>] resources mirroring files attached to `pcdm_object`
      def convert_and_add_file_to_resource(af_file, resource)
        attrs = attributes_from_af_file(af_file)
        file_metadata_set = resource.file_metadata.dup
        file_metadata_set << FileMetadata.new(**attrs)
        resource.file_metadata = file_metadata_set
      end

      def convert_and_add_file_to_af_object(file_metadata, af_object)
        return unless file_metadata.file_identifiers.present?
        af_file = Hydra::PCDM::File.find(file_metadata.file_identifiers.first)
        attrs = attributes_from_file_metadata_resource(file_metadata)
        attrs.each do |key, value|
          puts "UNABLE TO SET ON AF METADATA_NODE: key=#{key}   value=#{value}" unless af_file.respond_to? key # TODO: files -- resolve each of these
          af_file.metadata_node.set_value(key, value) if af_file.respond_to? key
        end
        af_file.mime_type = file_metadata.mime_type
        types(file_metadata) { |type| Hydra::PCDM::AddTypeToFile.call(af_file, type) }

        ### TODO: files -- WORKING ON HOW TO SET THE FILE ON THE FILESET
        # af_file.content = file_metadata.content if file_metadata.content.present?
        af_object.files << af_file
        # Hydra::Works::AddFileToFileSet.call(af_object,
        #                                     io,
        #                                     relation,
        #                                     versioning: false)
      end

      private
        def attributes_from_af_file(af_file)
          content = content(af_file)
          attrs = af_file.metadata_node.attributes.keys.map(&:to_sym)
          attrs.each_with_object({}) do |attr_name, attr_hash|
            next unless af_file.metadata_node.respond_to? attr_name
            attr_hash[attr_name.to_sym] = TransformerValueMapper.for(af_file.metadata_node.public_send(attr_name)).result
          end
              .merge(file_identifiers: [af_file.id],
                     mime_type: TransformerValueMapper.for(af_file.public_send(:mime_type)).result,
                     # content: TransformerValueMapper.for(content).result,
                     use: TransformerValueMapper.for(uses(af_file)).result)
        end

        def attributes_from_file_metadata_resource(file_metadata)
          attrs = file_metadata.attributes.dup
          attrs.delete(:file_identifiers)
          attrs.delete(:id)
          attrs.delete(:alternate_ids)
          attrs.delete(:internal_resource)
          attrs.delete(:new_record)
          attrs.delete(:created_at)
          attrs.delete(:updated_at)
          attrs.delete(:content)
          attrs.delete(:mimetype)
          attrs.delete(:use)
          attrs.compact
          attrs
        end

        def content(af_file)
          content = af_file.content
          content.is_a?(String) ? content : nil
        end

        # NOTE: Hyrax uses RDF::URI and Valkyrie uses RDF::Vocabulary::Term
        def uses(af_file)
          af_file.metadata_node.type.map do |type|
            next ::Valkyrie::Vocab::PCDMUse.OriginalFile if type == ::RDF::URI('http://pcdm.org/use#OriginalFile')
            next ::Valkyrie::Vocab::PCDMUse.ThumbnailFile if type == ::RDF::URI('http://pcdm.org/use#ThumbnailFile')
            next ::Valkyrie::Vocab::PCDMUse.ExtractedFile if type == ::RDF::URI('http://pcdm.org/use#ExtractedFile')
            type
          end
        end

        # NOTE: Hyrax uses RDF::URI and Valkyrie uses RDF::Vocabulary::Term
        def types(file_metadata)
          file_metadata.use.map do |use|
            next ::RDF::URI('http://pcdm.org/use#OriginalFile') if use == ::Valkyrie::Vocab::PCDMUse.OriginalFile
            next ::RDF::URI('http://pcdm.org/use#ThumbnailFile') if use == ::Valkyrie::Vocab::PCDMUse.ThumbnailFile
            next ::RDF::URI('http://pcdm.org/use#ExtractedFile') if use == ::Valkyrie::Vocab::PCDMUse.ExtractedFile
          end
        end
    end
  end
end
