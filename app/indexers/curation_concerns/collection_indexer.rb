module CurationConcerns
  class CollectionIndexer < Hydra::PCDM::CollectionIndexer
    include IndexesThumbnails
    STORED_LONG = Solrizer::Descriptor.new(:long, :stored)

    def generate_solr_document
      super.tap do |solr_doc|
        # Makes Collections show under the "Collections" tab
        Solrizer.set_field(solr_doc, 'generic_type', 'Collection', :facetable)
        # Index the size of the collection in bytes
        solr_doc[Solrizer.solr_name(:bytes, STORED_LONG)] = object.bytes
        solr_doc['thumbnail_path_ss'] = thumbnail_path

        object.in_collections.each do |col|
          (solr_doc['member_of_collection_ids_ssim'] ||= []) << col.id
          (solr_doc['member_of_collections_ssim'] ||= []) << col.first_title
        end
      end
    end
  end
end
