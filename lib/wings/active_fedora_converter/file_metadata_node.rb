# frozen_string_literal: true

module Wings
  class ActiveFedoraConverter
    def self.FileMetadataNode(resource_class) # rubocop:disable Naming/MethodName
      class_cache[resource_class] ||= Class.new(FileMetadataNode) do
        self.valkyrie_class = resource_class

        # skip reserved attributes, we assume we don't need to translate valkyrie internals
        schema = resource_class.schema.reject do |key|
          resource_class.reserved_attributes.include?(key.name) ||
            key.name == :size
        end

        Wings::ActiveFedoraConverter.apply_properties(self, schema)
      end
    end
  end

  class FileMetadataNode < ActiveFedora::Base
    property :file_set_id, predicate: ::RDF::URI.intern("http://hyrax.samvera.org/ns/wings#file_set_id")
    property :file_identifier, predicate: ::RDF::URI.intern("http://hyrax.samvera.org/ns/wings#file_identifier")

    class_attribute :valkyrie_class

    def model_name(*)
      Hyrax::Name.new(valkyrie_class)
    end
  end
end
