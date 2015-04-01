module Sufia::SearchBuilder

  include BlacklightAdvancedSearch::AdvancedSearchBuilder
  include Hydra::Collections::SearchBehaviors

  def show_only_collections(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] += [
      ActiveFedora::SolrQueryBuilder.construct_query_for_rel(has_model: Collection.to_class_uri)
    ]
  end

  def show_only_resources_deposited_by_current_user(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] += [
      ActiveFedora::SolrQueryBuilder.construct_query_for_rel(depositor: scope.current_user.user_key)
    ]
  end

  def show_only_generic_files(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] += [
      ActiveFedora::SolrQueryBuilder.construct_query_for_rel(has_model: ::GenericFile.to_class_uri)
    ]
  end

  def show_only_shared_files(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] += [
      "-" + ActiveFedora::SolrQueryBuilder.construct_query_for_rel(depositor: scope.current_user.user_key)
    ]
  end

  def show_only_highlighted_files(solr_parameters)
    ids = scope.current_user.trophies.pluck(:generic_file_id)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] += [
      ActiveFedora::SolrQueryBuilder.construct_query_for_ids(ids)
    ]
  end

  # Limits search results just to GenericFiles and collections
  # @param solr_parameters the current solr parameters
  # @param user_parameters the current user-subitted parameters
  def only_generic_files_and_collections(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "#{Solrizer.solr_name("has_model", :symbol)}:(\"GenericFile\" \"Collection\")"
  end

end
