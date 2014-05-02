module Worthwhile
  class GenericWork < ActiveFedora::Base
    has_metadata "descMetadata", type: GenericFileRdfDatastream
    has_metadata "properties", type: PropertiesDatastream


    has_attributes :depositor, :representative, datastream: :properties, multiple: false
    has_attributes :date_uploaded, :date_modified, :title, :description, datastream: :descMetadata, multiple: false 
    has_attributes :related_url, :based_near, :part_of, :creator, :contributor, :tag, :rights, 
                   :publisher, :date_created, :subject, :resource_type, :identifier, :language, 
                   datastream: :descMetadata, multiple: true

    include ::CurationConcern::WithGenericFiles
    include ::CurationConcern::HumanReadableType
    include Hydra::AccessControls::Permissions
    include ::CurationConcern::Embargoable
    include ::CurationConcern::WithEditors
    include Sufia::ModelMethods
  end
end
