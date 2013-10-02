module Sufia
  module GenericFile
    extend ActiveSupport::Concern
    extend ActiveSupport::Autoload
    autoload :Actions, 'sufia/models/generic_file/actions'
    autoload :Permissions, 'sufia/models/generic_file/permissions'
    autoload :WebForm, 'sufia/models/generic_file/web_form'
    autoload :AccessibleAttributes, 'sufia/models/generic_file/accessible_attributes'
    autoload :Trophies, 'sufia/models/generic_file/trophies'
    autoload :Metadata, 'sufia/models/generic_file/metadata'
    autoload :Versions, 'sufia/models/generic_file/versions'
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
    include Sufia::GenericFile::Trophies
    include Sufia::GenericFile::Metadata
    include Sufia::GenericFile::Versions

    included do
      belongs_to :batch, :property => :is_part_of

      around_save :characterize_if_changed, :retry_warming

      attr_accessible *(ds_specs['descMetadata'][:type].fields + [:permissions])
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
