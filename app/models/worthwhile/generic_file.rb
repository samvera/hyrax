module Worthwhile
  class GenericFile < ActiveFedora::Base
    include Sufia::ModelMethods
    include Hydra::AccessControls::Permissions
    include Sufia::Noid
    include Sufia::GenericFile::Characterization
    include Sufia::GenericFile::Versions
    include Sufia::GenericFile::Audit
    include Sufia::GenericFile::MimeTypes
    include Sufia::GenericFile::Derivatives
    include Sufia::GenericFile::Metadata
    include Sufia::GenericFile::WebForm
    include ::CurationConcern::Embargoable
    include Worthwhile::GenericFile::VersionedContent
    
    before_destroy :remove_representative_relationship

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

    def remove_representative_relationship
      return unless batch.representative == self.pid
      batch.representative = nil
      batch.save
    end

    def to_solr(solr_doc = {})
      super.tap do |solr_doc|
        # patch until https://github.com/projecthydra/sufia/pull/453 is merged (4.0.0 beta 4)
        solr_doc['desc_metadata__title_sim'] = solr_doc['desc_metadata__title_tesim']

        # Enables Riiif to not have to recalculate this each time.
        solr_doc['height_isi'] = Integer(height.first) if height.present?
        solr_doc['width_isi'] = Integer(width.first) if width.present?
      end
    end

    class << self
      # patch until https://github.com/projecthydra/sufia/pull/467 is merged (4.0.0 beta 5)
      def image_mime_types
        super + ['image/tiff']
      end
    end
  end
end

