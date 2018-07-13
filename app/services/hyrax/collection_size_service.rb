# returns a list of solr documents for collections the item is a part of
module Hyrax
  ##
  # @deprecated This class is broken for base Hyrax applications. Current users
  #   should call with extreme caution and consider a local implementation as
  #   an alternative.
  # @see https://github.com/samvera/hyrax/issues/2801
  class CollectionSizeService
    include Blacklight::Configurable
    include Blacklight::SearchHelper

    attr_reader :collection

    copy_blacklight_config_from(CatalogController)

    def self.run(collection)
      new(collection).collection_size
    end

    def initialize(collection)
      Deprecation
        .warn(self, 'CollectionSizeService has been deprecated for removal in ' \
                    'Hyrax 3.0. This class is broken for base Hyrax ' \
                    'applications. Current users should call with extreme ' \
                    'caution and consider a local implementation as an ' \
                    'alternative.')

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
      ActiveFedora.index_field_mapper.solr_name(:file_size, :symbol)
    end

    def max_collection_size
      1000
    end
  end
end
