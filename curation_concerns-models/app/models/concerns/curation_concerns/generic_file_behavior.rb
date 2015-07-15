module CurationConcerns
  module GenericFileBehavior
    extend ActiveSupport::Concern
    include Hydra::Works::GenericFileBehavior
    include Hydra::WithDepositor
    include CurationConcerns::Serializers
    include CurationConcerns::Noid
    include CurationConcerns::Permissions
    include CurationConcerns::GenericFile::Export
    include CurationConcerns::GenericFile::Characterization
    include CurationConcerns::GenericFile::BasicMetadata
    include CurationConcerns::GenericFile::Content
    include CurationConcerns::GenericFile::VirusCheck
    include CurationConcerns::GenericFile::FullTextIndexing
    include Hydra::Collections::Collectible
    include CurationConcerns::GenericFile::Indexing
    include CurationConcerns::GenericFile::BelongsToWorks
    include Hydra::AccessControls::Embargoable

    included do
      attr_accessor :file

      # make filename single-value (CurationConcerns::GenericFile::Characterization makes it multivalue)
      def filename
        if self[:filename].instance_of?(Array)
          self[:filename].first
        else
          self[:filename]
        end
      end
    end

    def generic_work?
      false
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

    def to_solr(solr_doc = {})
      super(solr_doc).tap do |solr_doc|
        # Enables Riiif to not have to recalculate this each time.
        solr_doc['height_isi'] = Integer(height.first) if height.present?
        solr_doc['width_isi'] = Integer(width.first) if width.present?
      end
    end
  end
end
