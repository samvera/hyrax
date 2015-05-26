class CurationConcerns::SearchBuilder < Hydra::SearchBuilder

  def only_generic_files_and_curation_concerns(solr_parameters)
    solr_parameters[:fq] ||= []
    types_to_include = CurationConcerns.configuration.registered_curation_concern_types.dup
    types_to_include << "Collection"
    formatted_type_names = types_to_include.map{|class_name| "\"#{class_name}\""}.join(" ")

    solr_parameters[:fq] << "#{Solrizer.solr_name("has_model", :symbol)}:(#{formatted_type_names})"

    # CurationConcerns.configuration.registered_curation_concern_types.each do |curation_concern_class_name|
    #   solr_parameters[:fq] << "#{Solrizer.solr_name("has_model", :symbol)}:(\"GenericFile\" \"Collection\")"
    # end
  end

  # Override Hydra::AccessControlsEnforcement (or Hydra::PolicyAwareAccessControlsEnforcement)
  # Allows admin users to see everything (don't apply any gated_discovery_filters for those users)
  def gated_discovery_filters(permission_types = discovery_permissions, ability = current_ability)
    return [] if ability.current_user.groups.include? 'admin'
    super
  end

  # show only files with edit permissions in lib/hydra/access_controls_enforcement.rb apply_gated_discovery
  def discovery_permissions
    return ["edit"] if blacklight_params[:works] == 'mine'
    super
  end


  # This is included as part of blacklight search solr params logic
  def filter_models(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << '(' + (work_clauses + collection_clauses).join(' OR ') + ')'
  end

  def work_clauses
    return [] if blacklight_params.has_key?(:f) && Array(blacklight_params[:f][:generic_type_sim]).include?('Collection')
    CurationConcerns.configuration.registered_curation_concern_types.map(&:constantize).map do |klass|
      ActiveFedora::SolrQueryBuilder.construct_query_for_rel(has_model: klass.to_class_uri)
    end
  end

  def collection_clauses
    return [] if blacklight_params.has_key?(:f) && Array(blacklight_params[:f][:generic_type_sim]).include?('Work')
    [ActiveFedora::SolrQueryBuilder.construct_query_for_rel(has_model: ::Collection.to_class_uri)]
  end
end

