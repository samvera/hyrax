module Hydra::AccessControlsEnforcement
  def exclude_unwanted_models(solr_parameters, user_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "-has_model_s:\"info:fedora/afmodel:Batch\""
  end
end
