module Hydra::SubmissionWorkflow
  def self.included(base)
    base.before_filter :validate_workflow_step if base.respond_to?(:before_filter)
  end
  
  def validate_workflow_step
    if workflow_config.has_key?(params[:action].to_sym)
      validation_method = "#{params[:action]}_#{get_af_model(:id => params[:id])}_validation".to_sym
      if self.respond_to?(validation_method) and self.send(validation_method) === false
        redirect_to :back
      end
    end
  end
  
  def next_step_in_workflow(current_step)
    if workflow_config[current_step.to_sym].has_key?(:next_step)
      workflow_config[current_step.to_sym][:next_step]
    else
      nil
    end
  end
  
  def first_step_in_workflow
    workflow_config.each do |step,config|
      return step if config[:order_of_step] == 0
    end
  end
  
  def workflow_partial_for_step(step)
    workflow_config[step.to_sym][:partial]
  end
  
  def model_config(options={})
    if !@document.nil?
      # If we have a document instance variable we can be fairly confident that is the object we are talking about.
      _model = get_af_model
      workflow_config_test[_model] if workflow_config_test.has_key?(_model)
    elsif options.has_key?(:model)
      # If we directly provide a model just return that configuration.
      workflow_config_test[options[:model]] if workflow_config_test.has_key?(options[:model].to_sym)
    elsif options.has_key?(:id) or params.has_key?(:id)
      # If we are providing the ID of an object (or there is an ID in the params hash) load the model from solr.
      # This will only be used in the case where we need to know the workflow of an item that we aren't actually looking at.
      options[:id] = params[:id] if params.has_key?(:id) and !options.has_key?(:id)
      _model = get_af_model(:id => options[:id])
      workflow_config_test[_model] if workflow_config_test.has_key?(_model)
    else 
      # don't know if we even want to do this.  Just having something to fall back on for now.
      workflow_config
    end
  end
  
  def get_af_model(options={})
    if !@document.nil? and @document.has_key?(:has_model_s) 
      # I'm a little suspicious about the line below.  Can I count on this naming convention?
      return @document[:has_model_s].first.gsub("info:fedora/afmodel:","").underscore.pluralize.to_sym
    elsif options.has_key?(:id)
      af = ActiveFedora::Base.load_instance_from_solr(options[:id])
      return "#{ActiveFedora::ContentModel.known_models_for( af ).first}".underscore.pluralize.to_sym
    end
  end
  
  def workflow_config_test
    {
      :mods_assets =>      [{:name => "contributor",     :partial => "contributors/contributor_form"},
                            {:name => "publication",     :partial => "mods_assets/publication_form"},
                            {:name => "additional_info", :partial => "modes_assets/additional_info_form"},
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
  
  def workflow_config
    # This is probably what it should look like.  Will refactor to look like this soon.
    # {
    #   :mods_assets => [{:name => "contributor", :partial => "contributor_form"},
    #                    {:name => "publication", :partial => "publication_form"},
    #                    {:name => "additional_info", :partial => "additional_info_form"},
    #                    {:name => "files", :partial => "file_assets/file_assets_form"}
    #                   ]
    # }
    
    {
      :contributor     => {:order_of_step => 0, :partial => "contributors/contributor_form", :next_step => :publication},
      :publication     => {:order_of_step => 1, :partial => "mods_assets/publication_form", :next_step => :additional_info},
      :additional_info => {:order_of_step => 2, :partial => "mods_assets/additional_info_form", :next_step => :files},
      :files           => {:order_of_step => 3, :partial => "file_assets/file_assets_form", :next_step => :permissions},
      :permissions     => {:order_of_step => 4, :partial => "permissions/permissions_form", :next_step => nil}
    }
  end
end