module Worthwhile
  class GenericFile < ActiveFedora::Base
    include Sufia::ModelMethods
    include Hydra::AccessControls::Permissions
    include Sufia::Noid
    include Sufia::GenericFile::Characterization
    include Sufia::GenericFile::Versions
    include Sufia::GenericFile::Audit
    include Sufia::GenericFile::MimeTypes
    include Sufia::GenericFile::Thumbnail
    include Sufia::GenericFile::Derivatives
    include Sufia::GenericFile::Metadata
    include ::CurationConcern::Embargoable
    include Worthwhile::GenericFile::VersionedContent
    
    belongs_to :batch, property: :is_part_of, class_name: 'ActiveFedora::Base'
    attr_accessor :file
    
    # make filename single-value (Sufia::GenericFile::Characterization makes it multivalue)
    # has_attributes :filename, datastream: :characterization, multiple: false
    def filename
      content.label
    end
    
  end
end

