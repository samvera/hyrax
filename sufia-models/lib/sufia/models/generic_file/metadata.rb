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
      end
    end
  end
end
