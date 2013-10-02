module Sufia
  module GenericFile
    module Metadata
      extend ActiveSupport::Concern

      included do
        has_metadata "descMetadata", type: GenericFileRdfDatastream
        has_metadata "properties", type: PropertiesDatastream
        has_file_datastream "content", type: FileContentDatastream
        has_file_datastream "thumbnail"


        delegate_to :properties, [:relative_path, :depositor, :import_url], multiple: false
        delegate_to :descMetadata, [:date_uploaded, :date_modified], multiple: false 
        delegate_to :descMetadata, [:related_url, :based_near, :part_of, :creator,
                                    :contributor, :title, :tag, :description, :rights,
                                    :publisher, :date_created, :subject,
                                    :resource_type, :identifier, :language], multiple: true
      end
    end
  end
end
