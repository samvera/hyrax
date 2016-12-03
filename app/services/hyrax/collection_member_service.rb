# returns a list of solr documents for collections the item is a part of
module Hyrax
  class CollectionMemberService
    include Blacklight::Configurable
    include Blacklight::SearchHelper

    attr_reader :item

    copy_blacklight_config_from(CatalogController)

    # @param [SolrDocument] item represents a work
    def self.run(item)
      new(item).list_collections
    end

    def initialize(item)
      @item = item
    end

    def list_collections
      query = collection_search_builder.rows(1000)
      resp = repository.search(query)
      resp.documents
    end

    def collection_search_builder
      @collection_search_builder ||= ParentCollectionSearchBuilder.new([:include_item_ids, :add_paging_to_solr], self)
    end
  end
end
