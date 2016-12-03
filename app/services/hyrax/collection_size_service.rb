# returns a list of solr documents for collections the item is a part of
module Hyrax
  class CollectionSizeService
    include Blacklight::Configurable
    include Blacklight::SearchHelper

    attr_reader :collection

    copy_blacklight_config_from(CatalogController)

    def self.run(collection)
      new(collection).collection_size
    end

    def initialize(collection)
      @collection = collection
    end

    def collection_size
      query = collection_search_builder.with('id' => collection.id).rows(max_collection_size).merge(fl: [size_field])
      resp = repository.search(query)
      field_name = size_field
      resp.documents.reduce(0) do |total, doc|
        total + (doc[field_name].blank? ? 0 : doc[field_name][0].to_f)
      end
    end

    def collection_search_builder
      @collection_search_builder ||= MemberWithFilesSearchBuilder.new([:include_contained_files, :add_paging_to_solr], self)
    end

    def size_field
      Solrizer.solr_name(:file_size, :symbol)
    end

    def max_collection_size
      1000
    end
  end
end
