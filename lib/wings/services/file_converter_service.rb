# frozen_string_literal: true
# Conversion service for going between files on a valkyrie resource and files on an active fedora object
module Wings
  class FileConverterService
    class << self
      def af_file_to_resource(af_file:)
        return if af_file&.id.blank?
        attrs = base_af_file_attributes(af_file: af_file)
        attrs = metadata_node_to_attributes(metadata_node: af_file.metadata_node,
                                            attributes: attrs)
        Hyrax::FileMetadata.new(attrs)
      end

      def resource_to_af_file(metadata_resource:)
        return if metadata_resource&.alternate_ids.blank?
        af_file = Hydra::PCDM::File.new(id: metadata_resource.alternate_ids.first.to_s)
        af_file.content = content(metadata_resource)
        af_file.original_name = metadata_resource.original_filename.first
        af_file.mime_type = metadata_resource.mime_type.first
        valkyrie_attributes_to_af_file(attributes: metadata_resource.attributes,
                                       af_file: af_file)
        af_file
      end

      private

      # extracts attributes that come from the af_file
      def base_af_file_attributes(af_file:)
        id = ::Valkyrie::ID.new(af_file.id)
        { id: id,
          alternate_ids: [id],
          file_identifier: id,
          created_at: af_file.create_date,
          updated_at: af_file.modified_date,
          content: af_file.content,
          size: af_file.size,
          original_filename: [af_file.original_name],
          mime_type: [af_file.mime_type],
          type: af_file.metadata_node.type.to_a }
      end

      # extracts attributes that come from the metadata_node
      def metadata_node_to_attributes(metadata_node:, attributes:)
        af_attrs = metadata_node.attributes.dup
        af_attrs.delete('id')
        af_attrs.each { |k, v| attributes[k.to_sym] = Array(v) unless attributes.key?(k.to_sym) }
        attributes
      end

      def valkyrie_attributes_to_af_file(attributes:, af_file:)
        attributes.each do |k, v|
          next if [:id, :content, :type].include? k
          mname = (k.to_s + '=').to_sym
          if af_file.respond_to? mname
            af_file.send(mname, v)
          elsif af_file.metadata_node.respond_to? mname
            af_file.metadata_node.send(mname, v)
          end
        end
      end

      def content(metadata_resource)
        return nil if metadata_resource.content.blank?
        metadata_resource.content.first
      end
    end
  end
end
