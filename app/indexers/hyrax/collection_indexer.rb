module Hyrax
  class CollectionIndexer < Hydra::PCDM::CollectionIndexer
    include Hyrax::IndexesThumbnails

    STORED_LONG = ActiveFedora::Indexing::Descriptor.new(:long, :stored)

    self.thumbnail_path_service = Hyrax::CollectionThumbnailPathService

    # @yield [Hash] calls the yielded block with the solr document
    # @return [Hash] the solr document WITH all changes
    def generate_solr_document
      super.tap do |solr_doc|
        # Makes Collections show under the "Collections" tab
        ActiveFedora.index_field_mapper.set_field(solr_doc, 'generic_type', 'Collection', :facetable)
        # Index the size of the collection in bytes
        solr_doc[ActiveFedora.index_field_mapper.solr_name(:bytes, STORED_LONG)] = object.bytes
        solr_doc['visibility_ssi'] = object.visibility

        object.in_collections.each do |col|
          (solr_doc['member_of_collection_ids_ssim'] ||= []) << col.id
          (solr_doc['member_of_collections_ssim'] ||= []) << col.to_s
        end
      end
    end
  end
end
