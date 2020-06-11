# frozen_string_literal: true
# Added to allow for the My controller to show only things I have edit access to
class Hyrax::My::CollectionsSearchBuilder < ::SearchBuilder
  include Hyrax::My::SearchBuilderBehavior
  include Hyrax::FilterByType

  self.default_processor_chain += [:show_only_collections_deposited_by_current_user]

  # adds a filter to the solr_parameters that filters the collections and admin sets
  # the current user has deposited
  # @param [Hash] solr_parameters
  def show_only_collections_deposited_by_current_user(solr_parameters)
    clauses = [
      ActiveFedora::SolrQueryBuilder.construct_query_for_rel(depositor: current_user_key),
      ActiveFedora::SolrQueryBuilder.construct_query_for_rel(has_model: ::AdminSet.to_s, creator: current_user_key)
    ]
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] += ["(#{clauses.join(' OR ')})"]
  end

  # This overrides the models in FilterByType
  # @return [Array<Class>] a list of classes to include
  def models
    [::AdminSet, ::Collection]
  end
end
