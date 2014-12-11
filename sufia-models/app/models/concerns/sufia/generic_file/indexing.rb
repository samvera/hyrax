module Sufia
  module GenericFile
    module Indexing
      extend ActiveSupport::Concern

      # Unstemmed, searchable, stored
      def self.noid_indexer
        @noid_indexer ||= Solrizer::Descriptor.new(:text, :indexed, :stored)
      end

      def to_solr(solr_doc={})
        super.tap do |solr_doc|
          solr_doc[Solrizer.solr_name('label')] = label
          solr_doc[Solrizer.solr_name('noid', Sufia::GenericFile::Indexing.noid_indexer)] = noid
          solr_doc[Solrizer.solr_name('file_format')] = file_format
          solr_doc[Solrizer.solr_name('file_format', :facetable)] = file_format
          solr_doc['all_text_timv'] = full_text.content
          solr_doc = index_collection_ids(solr_doc)
        end
      end
    end
  end
end
