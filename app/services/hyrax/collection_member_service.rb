# frozen_string_literal: true

module Hyrax
  ##
  # Returns a list of solr documents for collections the item is a part of
  class CollectionMemberService
    include Blacklight::Configurable

    attr_reader :item, :current_ability

    copy_blacklight_config_from(CatalogController)

    ##
    # @param [SolrDocument] item represents a work
    # @param [Hyrax::Ability] ability
    def self.run(item, ability)
      new(item, ability).list_collections
    end

    def initialize(item, ability)
      @item = item
      @current_ability = ability
    end

    def list_collections
      query = collection_search_builder.rows(1000)
      resp = blacklight_config.repository.search(query)
      resp.documents
    end

    def collection_search_builder
      @collection_search_builder ||= ParentCollectionSearchBuilder.new([:include_item_ids, :add_paging_to_solr, :add_access_controls_to_solr_params], self)
    end
  end
end
