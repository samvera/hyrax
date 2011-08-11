module Hydra::SubmissionWorkflow
  def self.included(base)
    base.before_filter :validate_workflow_step if base.respond_to?(:before_filter)
  end
  
  def validate_workflow_step
    unless model_config.nil?
      unless find_workflow_step_by_name(params[:action]).nil?
      #if workflow_config.has_key?(params[:action].to_sym)
        validation_method = "#{params[:action]}_#{get_af_model(:id => params[:id])}_validation".to_sym
        if self.respond_to?(validation_method) and self.send(validation_method) === false
          redirect_to :back
        end
      end
    end
  end
  
  def next_step_in_workflow(current_step)
    unless model_config.nil?
      model_config.each_with_index do |step,i|
        return model_config[i+1][:name] if step[:name] == current_step.to_s and step != model_config.last
      end
    end
    nil
  end
  
  def first_step_in_workflow
    model_config.first[:name]
  end
  
  def workflow_partial_for_step(step)
    find_workflow_step_by_name(step)[:partial]
  end
  
  def find_workflow_step_by_name(name)
    model_config.find{|config| config[:name] == name.to_s} unless model_config.nil?
  end
  
  def model_config(options={})
    if !@document.nil?
      # If we have a document instance variable we can be fairly confident that is the object we are talking about.
      _model = get_af_model
      return workflow_config[_model] if !_model.nil? and workflow_config.has_key?(_model)
    elsif options.has_key?(:model)
      # If we directly provide a model just return that configuration.
      return workflow_config[options[:model]] if workflow_config.has_key?(options[:model].to_sym)
    elsif options.has_key?(:id) or params.has_key?(:id)
      # If we are providing the ID of an object (or there is an ID in the params hash) load the model from solr.
      # This will only be used in the case where we need to know the workflow of an item that we aren't actually looking at.
      options[:id] = params[:id] if params.has_key?(:id) and !options.has_key?(:id)
      _model = get_af_model(:id => options[:id])
      return workflow_config[_model] if !_model.nil? and workflow_config.has_key?(_model)
    else 
      # don't know if we even want to do this.  Just having something to fall back on for now.
#      workflow_config
      return nil
    end
    nil
  end
  
  def get_af_model(options={})
    if !@document.nil?
      # I'm a little suspicious about this.  Can I count on this naming convention?
      if @document.is_a?(SolrDocument)
        return @document[:has_model_s].first.gsub("info:fedora/afmodel:","").underscore.pluralize.to_sym
      else
        return @document.class.to_s.underscore.pluralize.to_sym
      end
    elsif options.has_key?(:id)
      begin
        af = ActiveFedora::Base.load_instance_from_solr(options[:id])
        return "#{ActiveFedora::ContentModel.known_models_for( af ).first}".underscore.pluralize.to_sym
      rescue
        return nil
      end
    end
  end
  
  def workflow_config
    {
      :mods_assets =>      [{:name => "contributor",     :partial => "contributors/contributor_form"},
                            {:name => "publication",     :partial => "mods_assets/publication_form"},
                            {:name => "additional_info", :partial => "mods_assets/additional_info_form"},
                            {:name => "files",           :partial => "file_assets/file_assets_form"},
                            {:name => "permissions",     :partial => "permissions/permissions_form"}
                           ],
      :generic_contents => [{:name => "description", :partial => "generic_content_objects/edit_description"},
                            {:name => "files",       :partial => "file_assets/file_assets_form"},
                            {:name => "permissions", :partial => "permissions/permissions_form"},
                            {:name => "contributor", :partial => "contributors/contributors_form"}
                           ]
    }    
  end

end