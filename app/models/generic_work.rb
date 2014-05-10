# Override this file locally if you want to define your own GenericWork class
class GenericWork < ActiveFedora::Base
  include ::CurationConcern::Work

  has_metadata "descMetadata", type: GenericFileRdfDatastream
  has_metadata "properties", type: Worthwhile::PropertiesDatastream

  has_attributes :depositor, :representative, datastream: :properties, multiple: false
  
  has_attributes :date_uploaded, :date_modified, :title, :description, 
                datastream: :descMetadata, multiple: false 
                
  has_attributes :related_url, :based_near, :part_of, :creator, :contributor, 
                 :tag, :rights, :publisher, :date_created, :subject, :resource_type,
                  :identifier, :language, 
                datastream: :descMetadata, multiple: true
end
