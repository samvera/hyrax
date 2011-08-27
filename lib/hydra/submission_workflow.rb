module Hydra::SubmissionWorkflow
  
  # When in this module is incuded in a controller (e.g. responds to :before_filter) add the validate_worflow_step method to the before filter chain.
  def self.included(base)
    base.before_filter :validate_workflow_step if base.respond_to?(:before_filter)
  end
  
  # To be used in a before_filter.  This will call a method with the #{af_model}_#{action_param}_validation.  If that method returns false then we will redirect back.  The controller method doing the validation should set an appropriate flash message.
  def validate_workflow_step
    unless model_config.nil?
      # we may want to use the workflow name instead of or in addition to the action in the validation naming convention.
      validation_method = "#{get_af_model_from_params}_#{params[:action]}_validation".to_sym
      if self.respond_to?(validation_method) and self.send(validation_method) === false
        redirect_to :back
      end
    end
  end

  # Returns the name field for the next step in the configuration for the current model given the current step.
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
  
  # Convenience method to return the first step of a models workflow.
  def first_step_in_workflow
    model_config.first[:name] unless model_config.nil?
  end
  
  # Convenience method to return the last step of a models workflow.
  def last_step_in_workflow
    model_config.last[:name] unless model_config.nil?
  end
  
  def params_for_next_step_in_wokflow
    return_params = {:wf_step=>next_step_in_workflow(params[:wf_step])}
    if params[:new_asset]
      return_params[:new_asset] = true
    end
    if params[:wf_step] == last_step_in_workflow or params.has_key?(:finish)
      flash[:notice] << "<br/>Your object has been saved and you have been redirected to the display view."
      return_params[:viewing_context] = "browse"
      return_params[:action] = "show" 
      return_params[:wf_step] = nil
    end
    return return_params
  end
  
  # Convenience method to return the partial for any given step by name.
  def workflow_partial_for_step(step)
    find_workflow_step_by_name(step)[:edit_partial]
  end
  
  # Convenience method to return an entire workflow step by name.
  def find_workflow_step_by_name(name)
    model_config.find{|config| config[:name] == name.to_s} unless model_config.nil?
  end
  
  # Returns an array of display partials for steps previous to the given step.
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
  
  # Returns an array of all edit partials for the current content type.
  def all_edit_partials
    edit_partials = []
    unless model_config.nil?
      model_config.each do |config|
        edit_partials << config[:edit_partial]
      end
    end
    edit_partials
  end
  
  # Will return the entire workflow configuration for the current model.
  # We determing model first by seeing the @document object is a SolrDocument.  If it is we will determing from the has_model_s field.
  # Otherwise we will attemtp to determine by the parameters (content_type directly passed or the id of an object).
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
  
  # Reutrns a symbolized model name determined by parameters.
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
  
  # Convenience method to return the model from the @document objects has_model_s field.
  def get_af_model_from_solr
    @document[:has_model_s].first.gsub("info:fedora/afmodel:","").underscore.pluralize.to_sym
  end

  # The configuration hash.  This should probably live somewhere else and get read in so it can be properly configured at the application level.  But for now it's here.
  def workflow_config
    Hydra.config[:submission_workflow]
  end

end