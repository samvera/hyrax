class Worthwhile::SearchBuilder < Hydra::SearchBuilder

  def only_generic_files_and_curation_concerns(solr_parameters)
    solr_parameters[:fq] ||= []
    types_to_include = Worthwhile.configuration.registered_curation_concern_types.dup
    types_to_include << "Collection"
    formatted_type_names = types_to_include.map{|class_name| "\"#{class_name}\""}.join(" ")

    solr_parameters[:fq] << "#{Solrizer.solr_name("has_model", :symbol)}:(#{formatted_type_names})"

    # Worthwhile.configuration.registered_curation_concern_types.each do |curation_concern_class_name|
    #   solr_parameters[:fq] << "#{Solrizer.solr_name("has_model", :symbol)}:(\"GenericFile\" \"Collection\")"
    # end
  end

  # Override Hydra::AccessControlsEnforcement (or Hydra::PolicyAwareAccessControlsEnforcement)
  # Allows admin users to see everything (don't apply any gated_discovery_filters for those users)
  def gated_discovery_filters(permission_types = discovery_permissions, ability = current_ability)
    return [] if ability.current_user.groups.include? 'admin'
    super
  end


end

