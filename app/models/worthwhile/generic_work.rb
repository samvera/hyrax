module Worthwhile
  class GenericWork < ActiveFedora::Base
      has_metadata "descMetadata", type: GenericFileRdfDatastream
      has_metadata "properties", type: PropertiesDatastream


      has_attributes :depositor, datastream: :properties, multiple: false
      has_attributes :date_uploaded, :date_modified, datastream: :descMetadata, multiple: false 
      has_attributes :related_url, :based_near, :part_of, :creator,
                                  :contributor, :title, :tag, :description, :rights,
                                  :publisher, :date_created, :subject,
                                  :resource_type, :identifier, :language, datastream: :descMetadata, multiple: true
  end
end
