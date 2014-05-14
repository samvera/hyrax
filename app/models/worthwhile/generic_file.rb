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
    include Sufia::GenericFile::WebForm
    include ::CurationConcern::Embargoable
    include Worthwhile::GenericFile::VersionedContent
    
    belongs_to :batch, property: :is_part_of, class_name: 'ActiveFedora::Base'
    attr_accessor :file
    
    # make filename single-value (Sufia::GenericFile::Characterization makes it multivalue)
    # has_attributes :filename, datastream: :characterization, multiple: false
    def filename
      content.label
    end
    
    def human_readable_type
      self.class.to_s.demodulize.titleize
    end
    
    def representative
      to_param
    end

    def copy_permissions_from(obj)
      self.datastreams['rightsMetadata'].ng_xml = obj.datastreams['rightsMetadata'].ng_xml
    end
    
    def update_parent_representative_if_empty(obj)
      return unless obj.representative.blank?
      obj.representative = self.pid
      obj.save
    end
    
  end
end

