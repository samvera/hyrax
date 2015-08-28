module CurationConcerns
  class GenericFileIndexingService < ActiveFedora::IndexingService
    def generate_solr_document
      super.tap do |solr_doc|
        solr_doc[Solrizer.solr_name('representative')] = object.representative
        # Label is the actual file name. It's not editable by the user.
        solr_doc[Solrizer.solr_name('label')] = object.label
        solr_doc[Solrizer.solr_name('label', :stored_sortable)] = object.label
        solr_doc[Solrizer.solr_name('file_format')] = object.file_format
        solr_doc[Solrizer.solr_name('file_format', :facetable)] = object.file_format
        solr_doc[Solrizer.solr_name(:file_size, :symbol)] = object.file_size[0]
        solr_doc['all_text_timv'] = object.full_text.content
        solr_doc[Solrizer.solr_name('generic_work_ids', :symbol)] = object.generic_work_ids unless object.generic_work_ids.empty?
        solr_doc['height_is'] = Integer(object.height.first) if object.height.present?
        solr_doc['width_is'] = Integer(object.width.first) if object.width.present?
      end
    end
  end
end
