module Sufia
  module GenericFile
    module Metadata
      extend ActiveSupport::Concern

      included do
        has_metadata "descMetadata", type: GenericFileRdfDatastream
        has_metadata "properties", type: PropertiesDatastream
        has_file_datastream "content", type: FileContentDatastream
        has_file_datastream "thumbnail"

        property :depositor, predicate: RDF::URI.new("http://id.loc.gov/vocabulary/relators/dpt") do |index|
          index.as :symbol, :stored_searchable
        end


        # Hack until https://github.com/no-reply/ActiveTriples/pull/37 is merged
        def depositor_with_first
          depositor_without_first.first
        end
        alias_method_chain :depositor, :first

        has_attributes :relative_path, :import_url, datastream: :properties, multiple: false
        has_attributes :date_uploaded, :date_modified, datastream: :descMetadata, multiple: false
        has_attributes :related_url, :based_near, :part_of, :creator,
                                    :contributor, :title, :tag, :description, :rights,
                                    :publisher, :date_created, :subject,
                                    :resource_type, :identifier, :language, datastream: :descMetadata, multiple: true
        property :label, predicate: RDF::DC.title

        # Hack until https://github.com/no-reply/ActiveTriples/pull/37 is merged
        def label_with_first
          label_without_first.first
        end
        alias_method_chain :label, :first
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
