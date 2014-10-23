module Worthwhile
  module GenericFileBase
    extend ActiveSupport::Concern
    include Hydra::AccessControls::Embargoable
    include Sufia::ModelMethods
    include Sufia::Noid
    include Sufia::GenericFile::MimeTypes
    include Sufia::GenericFile::Characterization
    include Sufia::GenericFile::Audit
    include Sufia::GenericFile::WebForm
    include Sufia::GenericFile::Derivatives
    include Sufia::GenericFile::Metadata
    include Sufia::GenericFile::Versions
    include Sufia::Permissions::Readable
    include ::CurationConcern::VersionedContent

    included do
      belongs_to :batch, property: :is_part_of, class_name: 'ActiveFedora::Base'

      before_destroy :remove_representative_relationship

      attr_accessor :file

      # make filename single-value (Sufia::GenericFile::Characterization makes it multivalue)
      # has_attributes :filename, datastream: :characterization, multiple: false
      def filename
        content.label
      end
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
      return unless ActiveFedora::Base.exists?(batch)
      return unless batch.representative == self.pid
      batch.representative = nil
      batch.save
    end

    def to_solr(solr_doc = {})
      super.tap do |solr_doc|
        # Enables Riiif to not have to recalculate this each time.
        solr_doc['height_isi'] = Integer(height.first) if height.present?
        solr_doc['width_isi'] = Integer(width.first) if width.present?
      end
    end
  end
end
