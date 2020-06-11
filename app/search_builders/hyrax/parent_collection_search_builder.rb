# frozen_string_literal: true
module Hyrax
  # Given the id of a work, find the collections it is a member of
  class ParentCollectionSearchBuilder < Hyrax::CollectionSearchBuilder
    delegate :item, to: :scope

    # include filters into the query to only include the collections containing this item
    def include_item_ids(solr_parameters)
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] += [Hyrax::SolrQueryBuilderService.construct_query_for_ids([item.member_of_collection_ids])]
    end
  end
end
