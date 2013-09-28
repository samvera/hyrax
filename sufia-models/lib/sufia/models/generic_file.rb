module Sufia
  module GenericFile
    extend ActiveSupport::Concern
    extend ActiveSupport::Autoload
    autoload :Actions, 'sufia/models/generic_file/actions'
    autoload :Permissions, 'sufia/models/generic_file/permissions'
    autoload :Visibility, 'sufia/models/generic_file/visibility'
    autoload :WebForm, 'sufia/models/generic_file/web_form'
    autoload :AccessibleAttributes, 'sufia/models/generic_file/accessible_attributes'
    include Sufia::ModelMethods
    include Sufia::Noid
    include Sufia::GenericFile::MimeTypes
    include Sufia::GenericFile::Thumbnail
    include Sufia::GenericFile::Export
    include Sufia::GenericFile::Characterization
    include Sufia::GenericFile::Audit
    include Sufia::GenericFile::Permissions
    include Sufia::GenericFile::WebForm
    include Sufia::GenericFile::Derivatives

    included do
      has_metadata :name => "descMetadata", :type => GenericFileRdfDatastream
      has_metadata :name => "properties", :type => PropertiesDatastream
      has_file_datastream :name => "content", :type => FileContentDatastream
      has_file_datastream :name => "thumbnail"

      belongs_to :batch, :property => :is_part_of

      delegate_to :properties, [:relative_path, :depositor, :import_url], multiple: false
      delegate_to :descMetadata, [:date_uploaded, :date_modified], multiple: false 
      delegate_to :descMetadata, [:related_url, :based_near, :part_of, :creator,
                                  :contributor, :title, :tag, :description, :rights,
                                  :publisher, :date_created, :subject,
                                  :resource_type, :identifier, :language], multiple: true

      around_save :characterize_if_changed, :retry_warming
      before_destroy :cleanup_trophies

      attr_accessible *(ds_specs['descMetadata'][:type].fields + [:permissions])
    end


    def record_version_committer(user)
      version = content.latest_version
      # content datastream not (yet?) present
      return if version.nil?
      VersionCommitter.create(:obj_id => version.pid,
                              :datastream_id => version.dsid,
                              :version_id => version.versionID,
                              :committer_login => user.user_key)
    end

    def pdf?
      self.class.pdf_mime_types.include? self.mime_type
    end

    def image?
      self.class.image_mime_types.include? self.mime_type
    end

    def video?
      self.class.video_mime_types.include? self.mime_type
    end

    def audio?
      self.class.audio_mime_types.include? self.mime_type
    end

    def persistent_url
      "#{Sufia.config.persistent_hostpath}#{noid}"
    end

    def retry_warming
        save_tries = 0
        conflict_tries = 0
        begin
          yield
        rescue RSolr::Error::Http => error
          save_tries += 1
          logger.warn "Retry Solr caught RSOLR error on #{self.pid}: #{error.inspect}"
          # fail for good if the tries is greater than 3
          raise if save_tries >=3
          sleep 0.01
          retry
        rescue  ActiveResource::ResourceConflict => error
          conflict_tries += 1
          logger.warn "Retry caught Active Resource Conflict #{self.pid}: #{error.inspect}"
          raise if conflict_tries >=10
          sleep 0.01
          retry
        rescue =>error
          if (error.to_s.downcase.include? "conflict")
            conflict_tries += 1
            logger.warn "Retry caught Active Resource Conflict #{self.pid}: #{error.inspect}"
            raise if conflict_tries >=10
            sleep 0.01
            retry
          else
            raise
          end
        end
    end

    def cleanup_trophies
      Trophy.destroy_all(generic_file_id: self.noid)
    end

    def related_files
      relateds = begin
                   self.batch.generic_files
                 rescue NoMethodError => e
                   #batch is nil - When would this ever happen?
                   batch_id = self.object_relations["isPartOf"].first || self.object_relations[:is_part_of].first
                   return [] if batch_id.nil?
                   self.class.find(Solrizer.solr_name('is_part_of', :symbol) => batch_id)
                 end
      relateds.reject { |gf| gf.pid == self.pid }
    end

    # Unstemmed, searchable, stored
    def self.noid_indexer
      @noid_indexer ||= Solrizer::Descriptor.new(:text, :indexed, :stored)
    end

    def to_solr(solr_doc={}, opts={})
      super(solr_doc, opts)
      solr_doc[Solrizer.solr_name('label')] = self.label
      solr_doc[Solrizer.solr_name('noid', Sufia::GenericFile.noid_indexer)] = noid
      solr_doc[Solrizer.solr_name('file_format')] = file_format
      solr_doc[Solrizer.solr_name('file_format', :facetable)] = file_format
      return solr_doc
    end

    def file_format
      return nil if self.mime_type.blank? and self.format_label.blank?
      return self.mime_type.split('/')[1]+ " ("+self.format_label.join(", ")+")" unless self.mime_type.blank? or self.format_label.blank?
      return self.mime_type.split('/')[1] unless self.mime_type.blank?
      return self.format_label
    end

    # Redefine this for more intuitive keys in Redis
    def to_param
      noid
    end

    def label=(new_label)
      @inner_object.label = new_label
      if self.title.empty?
        self.title = new_label
      end
    end

    # Is this file in the middle of being processed by a batch?
    def processing?
       return false if self.batch.blank?
       return false if !self.batch.methods.include? :status
       return (!self.batch.status.empty?) && (self.batch.status.count == 1) && (self.batch.status[0] == "processing")
    end
  end
end
