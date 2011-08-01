module Hydra::SubmissionWorkflow
  def self.included(base)
    base.before_filter :validate_workflow_step if base.respond_to?(:before_filter)
  end
  
  def validate_workflow_step
    action = "#{params[:action]}_validation".to_sym
    if self.respond_to?(action) and self.send(action) === false
      redirect_to :back
    end
  end
  
  def next_step_in_workflow(current_step)
    workflow_config[current_step.to_sym][:next_step]
  end
  
  # is this even used?
  def next_partial_in_workflow(current_step)
    workflow_config[next_step_in_workflow(current_step.to_sym)][:partial]
  end
  
  def first_step_in_workflow
    workflow_config.each do |step,config|
      return step if config[:order_of_step] == 0
    end
  end
  
  def workflow_partial_for_step(step)
    workflow_config[step.to_sym][:partial]
  end

  def workflow_config
    {
      :contributor     => {:order_of_step => 0, :partial => "mods_assets/contributor_form", :next_step => :publication},
      :publication     => {:order_of_step => 1, :partial => "mods_assets/publication_form", :next_step => :additional_info},
      :additional_info => {:order_of_step => 2, :partial => "mods_assets/additional_info_form", :next_step => :files},
      :files           => {:order_of_step => 3, :partial => "file_assets/file_assets_form", :next_step => :permissions}
    }
  end
end