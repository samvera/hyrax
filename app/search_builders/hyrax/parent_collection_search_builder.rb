# frozen_string_literal: true
module Hyrax
  # Given the id of a work, find the collections it is a member of
  class ParentCollectionSearchBuilder < Hyrax::CollectionSearchBuilder
    delegate :item, to: :scope

    # include filters into the query to only include the collections containing this item
    def include_item_ids(solr_parameters)
      ids = item.member_of_collection_ids
      solr_parameters[:fq] ||= []
      return solr_parameters[:fq] += ['-id:NEVER_USE_THIS_ID'] if ids.empty?
      solr_parameters[:fq] += [Hyrax::SolrQueryService.new.with_ids(ids: [ids]).build]
    end
  end
end
