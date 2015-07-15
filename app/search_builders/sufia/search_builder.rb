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

  def show_only_generic_works(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] += [
      ActiveFedora::SolrQueryBuilder.construct_query_for_rel(has_model: ::GenericWork.to_class_uri)
    ]
  end

  def show_only_shared_files(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] += [
      "-" + ActiveFedora::SolrQueryBuilder.construct_query_for_rel(depositor: scope.current_user.user_key)
    ]
  end

  def show_only_highlighted_works(solr_parameters)
    ids = scope.current_user.trophies.pluck(:generic_work_id)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] += [
      ActiveFedora::SolrQueryBuilder.construct_query_for_ids(ids)
    ]
  end

  # Limits search results just to GenericWorks and collections
  # @param solr_parameters the current solr parameters
  # @param user_parameters the current user-submitted parameters
  def only_works_and_collections(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "#{Solrizer.solr_name("has_model", :symbol)}:(\"GenericWork\" \"Collection\")"
  end

  # show both works that match the query and works that contain files that match the query
  def show_works_or_works_that_contain_files(solr_parameters)
    return if solr_parameters[:q].blank?
    solr_parameters[:user_query] = solr_parameters[:q]
    solr_parameters[:q] = new_query
  end

  protected

  # the {!lucene} gives us the OR syntax
  def new_query
    "{!lucene}#{ interal_query(dismax_query) } #{ interal_query(join_for_works_from_files) }"
  end

  # the _query_ allows for another parser (aka dismax)
  def interal_query( query_value)
     "_query_:\"#{query_value}\""
  end

  # the {!dismax} causes the query to go against the query fields
  def dismax_query
    "{!dismax v=$user_query}"
  end

  # join from file id to work relationship solrized generic_work_ids
  def join_for_works_from_files
    "{!join from=#{Solrizer.solr_name('generic_work_ids', :symbol)} to=id}#{dismax_query}"
  end
end
