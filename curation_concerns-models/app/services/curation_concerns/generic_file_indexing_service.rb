module CurationConcerns
  class GenericFileIndexingService < Hydra::PCDM::ObjectIndexer
    def generate_solr_document
      super.tap do |solr_doc|
        solr_doc[Solrizer.solr_name('label')] = object.label
        solr_doc[Solrizer.solr_name('file_format')] = object.file_format
        solr_doc[Solrizer.solr_name('file_format', :facetable)] = object.file_format
        solr_doc[Solrizer.solr_name(:file_size, :symbol)] = object.file_size[0]
        solr_doc['all_text_timv'] = object.full_text.content
        solr_doc[Solrizer.solr_name('generic_work_ids', :symbol)] = object.generic_work_ids unless object.generic_work_ids.empty?
      end
    end
  end
end
