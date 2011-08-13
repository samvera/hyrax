module Hydra::SubmissionWorkflow
  def self.included(base)
    base.before_filter :validate_workflow_step if base.respond_to?(:before_filter)
  end
  
  def validate_workflow_step
    unless model_config.nil?
      # we may want to use the workflow name instead of or in addition to the action in the validation naming convention.
      validation_method = "#{get_af_model_from_params}_#{params[:action]}_validation".to_sym
      if self.respond_to?(validation_method) and self.send(validation_method) === false
        redirect_to :back
      end
    end
  end
  
  def next_step_in_workflow(current_step)
    unless model_config.nil?
      if current_step.blank?
        # The first edit step won't have a wf_step param so we will need to pass it off to the 2nd step.
        return next_step_in_workflow(first_step_in_workflow)
      else
        model_config.each_with_index do |step,i|
          return model_config[i+1][:name] if step[:name] == current_step.to_s and step != model_config.last
        end
      end
    end
    nil
  end
  
  def first_step_in_workflow
    model_config.first[:name]
  end
  
  def workflow_partial_for_step(step)
    find_workflow_step_by_name(step)[:edit_partial]
  end
  
  def find_workflow_step_by_name(name)
    model_config.find{|config| config[:name] == name.to_s} unless model_config.nil?
  end
  
  def previous_show_partials(current_step)
    previous_partials = []
    # if there is no step then we are on the first step of the workflow and don't need to display anything.
    return previous_partials if current_step.blank?
    unless model_config.nil?
      model_config.each do |config|
        break if config[:name] == current_step.to_s
        previous_partials << config[:show_partial]
      end
    end
    previous_partials
  end
  
  def model_config
    # If we  can get it directly from solr get it there.
    if !@document.nil? and @document.is_a?(SolrDocument)
      _model = get_af_model_from_solr
      return workflow_config[_model] if !_model.nil? and workflow_config.has_key?(_model)
    
    # If we can get the model from the params get it there.
    elsif params.has_key?(:content_type) or params.has_key?(:id)
      _model = get_af_model_from_params
      return workflow_config[_model] if workflow_config.has_key?(_model) and !_model.nil?
    else 
      return nil
    end
    nil
  end
  
  def get_af_model_from_params
    if params.has_key?(:content_type)
      return params[:content_type].pluralize.to_sym
    else
      begin
        af = ActiveFedora::Base.load_instance_from_solr(params[:id])
        return "#{ActiveFedora::ContentModel.known_models_for( af ).first}".underscore.pluralize.to_sym
      rescue
        nil
      end
    end
  end
  
  def get_af_model_from_solr
    @document[:has_model_s].first.gsub("info:fedora/afmodel:","").underscore.pluralize.to_sym
  end



  def workflow_config
    {
      :mods_assets =>      [{:name => "contributor",     :edit_partial => "contributors/contributor_form",    :show_partial => "mods_assets/show_contributors"},
                            {:name => "publication",     :edit_partial => "mods_assets/publication_form",     :show_partial => "mods_assets/show_publication"},
                            {:name => "additional_info", :edit_partial => "mods_assets/additional_info_form", :show_partial => "mods_assets/show_additional_info"},
                            {:name => "files",           :edit_partial => "file_assets/file_assets_form",     :show_partial => "mods_assets/show_file_assets"},
                            {:name => "permissions",     :edit_partial => "permissions/permissions_form",     :show_partial => "mods_assets/show_permissions"}
                           ],
      :generic_contents => [{:name => "description", :edit_partial => "generic_content_objects/description_form", :show_partial => "generic_contents/show_description"},
                            {:name => "files",       :edit_partial => "file_assets/file_assets_form",             :show_partial => "file_assets/index"},
                            {:name => "permissions", :edit_partial => "permissions/permissions_form",             :show_partial => "generic_contents/show_permissions"},
                            {:name => "contributor", :edit_partial => "contributors/contributor_form",            :show_partial => "generic_Contents/show_contributors"}
                           ]
    }    
  end

end