class CurationConcerns::SearchBuilder < Hydra::SearchBuilder
  include BlacklightAdvancedSearch::AdvancedSearchBuilder
  include Hydra::Collections::SearchBehaviors

  def only_file_sets(solr_parameters)
    solr_parameters[:fq] << ActiveFedora::SolrQueryBuilder.construct_query_for_rel(has_model: FileSet.to_class_uri)
  end

  def find_one(solr_parameters)
    solr_parameters[:fq] << "_query_:\"{!raw f=id}#{blacklight_params.fetch(:id)}\""
  end

  # Override Hydra::AccessControlsEnforcement (or Hydra::PolicyAwareAccessControlsEnforcement)
  # Allows admin users to see everything (don't apply any gated_discovery_filters for those users)
  def gated_discovery_filters(permission_types = discovery_permissions, ability = current_ability)
    return [] if ability.current_user.groups.include? 'admin'
    super
  end

  # show only files with edit permissions in lib/hydra/access_controls_enforcement.rb apply_gated_discovery
  def discovery_permissions
    return ['edit'] if blacklight_params[:works] == 'mine'
    super
  end

  # This is included as part of blacklight search solr params logic
  def filter_models(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << '(' + (work_clauses + collection_clauses).join(' OR ') + ')'
  end

  def work_clauses
    return [] if blacklight_params.key?(:f) && Array(blacklight_params[:f][:generic_type_sim]).include?('Collection')
    CurationConcerns.config.registered_curation_concern_types.map(&:constantize).map do |klass|
      ActiveFedora::SolrQueryBuilder.construct_query_for_rel(has_model: klass.to_class_uri)
    end
  end

  def collection_clauses
    return [] if blacklight_params.key?(:f) && Array(blacklight_params[:f][:generic_type_sim]).include?('Work')
    [ActiveFedora::SolrQueryBuilder.construct_query_for_rel(has_model: ::Collection.to_class_uri)]
  end
end
