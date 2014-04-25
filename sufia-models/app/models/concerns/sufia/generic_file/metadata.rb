module Sufia
  module GenericFile
    module Metadata
      extend ActiveSupport::Concern

      included do
        has_metadata "descMetadata", type: GenericFileRdfDatastream
        has_metadata "properties", type: PropertiesDatastream
        has_file_datastream "content", type: FileContentDatastream
        has_file_datastream "thumbnail"

        has_attributes :relative_path, :depositor, :import_url, datastream: :properties, multiple: false
        has_attributes :date_uploaded, :date_modified, datastream: :descMetadata, multiple: false
        has_attributes :related_url, :based_near, :part_of, :creator,
                                    :contributor, :title, :tag, :description, :rights,
                                    :publisher, :date_created, :subject,
                                    :resource_type, :identifier, :language, datastream: :descMetadata, multiple: true
        attribute :label, [ RDF::DC.title, FedoraLens::Lenses.single, FedoraLens::Lenses.literal_to_string]
      end

      # Add a schema.org itemtype
      def itemtype
        # Look up the first non-empty resource type value in a hash from the config
        Sufia.config.resource_types_to_schema[resource_type.to_a.reject { |type| type.empty? }.first] || 'http://schema.org/CreativeWork'
      rescue
        'http://schema.org/CreativeWork'
      end
    end
  end
end
