module Sufia
  autoload :VirusFoundError, 'sufia/models/virus_found_error'

  module GenericFile
    extend ActiveSupport::Concern
    include Sufia::ModelMethods
    include Sufia::Noid
    include Sufia::GenericFile::MimeTypes
    include Sufia::GenericFile::Export
    include Sufia::GenericFile::Characterization
    include Sufia::GenericFile::Audit
    include Sufia::GenericFile::Permissions
    include Sufia::GenericFile::WebForm
    include Sufia::GenericFile::Derivatives
    include Sufia::GenericFile::Trophies
    include Sufia::GenericFile::Featured
    include Sufia::GenericFile::Metadata
    include Sufia::GenericFile::Versions
    include Sufia::GenericFile::VirusCheck
    include Sufia::GenericFile::ReloadOnSave
    include Sufia::GenericFile::FullTextIndexing
    include Sufia::GenericFile::ProxyDeposit
    include Hydra::Collections::Collectible

    included do
      belongs_to :batch, property: :is_part_of

      around_save :retry_warming

      attr_accessible *(terms_for_display + [:part_of, :permissions])
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
      rescue => error
        if error.to_s.downcase.include? "conflict"
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

    # Get the files with a sibling relationship (belongs_to :batch)
    # The batch id is minted when visiting the upload screen and attached
    # to each file when it is done uploading.  The Batch object is not created
    # until all objects are done uploading and the user is redirected to
    # BatchController#edit.  Therefore, we must handle the case where
    # self.batch_id is set but self.batch returns nil.
    def related_files
      return [] if batch.nil?
      batch.generic_files.reject { |sibling| sibling.id == id }
    end

    # Unstemmed, searchable, stored
    def self.noid_indexer
      @noid_indexer ||= Solrizer::Descriptor.new(:text, :indexed, :stored)
    end

    def to_solr(solr_doc={}, opts={})
      super(solr_doc, opts).tap do |solr_doc|
        solr_doc[Solrizer.solr_name('label')] = self.label
        solr_doc[Solrizer.solr_name('noid', Sufia::GenericFile.noid_indexer)] = noid
        solr_doc[Solrizer.solr_name('file_format')] = file_format
        solr_doc[Solrizer.solr_name('file_format', :facetable)] = file_format
        solr_doc['all_text_timv'] = full_text.content
        solr_doc = index_collection_pids(solr_doc)
      end
    end

    def label=(new_label)
      super
      if self.title.empty?
        self.title = [new_label].compact
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
