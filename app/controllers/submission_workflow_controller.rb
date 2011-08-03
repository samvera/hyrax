class SubmissionWorkflowController < ApplicationController
  include MediaShelf::ActiveFedoraHelper
  include Blacklight::SolrHelper
  include Hydra::RepositoryController
  include Hydra::AssetsControllerHelper
  include Hydra::SubmissionWorkflow
#  include ReleaseProcessHelper
  
  # probably need to do some sort of before filter to ensure security
  #before_filter :enforce_edit
  #before_filter :validate_workflow_step, :require_solr, :require_fedora
  before_filter :require_solr, :require_fedora
  
  # This should probably be in ContributorsController#create
  def contributor
    @document = load_document_from_params
    # generates sanatized params from params hash to update the doc with
    sanitize_update_params
    @response = update_document(@document,@sanitized_params)
    @document.save
    flash[:notice] = "Your changes have been saved."
    if params.has_key? :add_another_author
      redirect_to({:controller => "catalog", :action => "edit", :id => params[:id], :add_contributor => true})
    else
      redirect_to({:controller => "catalog", :action => "edit", :id => params[:id], :wf_step => next_step_in_workflow(:contributor)})
    end
  end
  
  # I don't really know where this should go.  Possibly the AssetsController?
  def publication
    @document = load_document_from_params
    # generates sanatized params from params hash to update the doc with
    sanitize_update_params
    @response = update_document(@document,@sanitized_params)
    @document.save
    flash[:notice] = "Your changes have been saved"
    redirect_to({:controller => "catalog", :action => "edit", :id => params[:id], :wf_step => next_step_in_workflow(:publication)})
  end
  
  # I don't really know where this should go.  Possibly the AssetsController?
  def additional_info
    @document = load_document_from_params
    # generates sanatized params from params hash to update the doc with
    sanitize_update_params
    @response = update_document(@document,@sanitized_params)
    @document.save
    flash[:notice] = "Your changes have been saved"
    redirect_to({:controller => "catalog", :action => "edit", :id => params[:id], :wf_step => next_step_in_workflow(:additional_info)})
  end
  
  # This should probably be in FileAssets#create
  # This method is mostly for handling the number of files drop down.
  def file_assets
    if params.has_key?(:number_of_files) and params[:number_of_files] != "0"
      redirect_to({:controller => "catalog", :action => "edit", :id => params[:id], :wf_step => :files, :number_of_files => params[:number_of_files]})
    elsif params.has_key?(:number_of_files) and params[:number_of_files] == "0"
      redirect_to({:controller => "catalog", :action => "edit", :id => params[:id], :wf_step => next_step_in_workflow(:files)})
    else
      @document = load_document_from_params
      # generates sanatized params from params hash to update the doc with
      sanitize_update_params
      @response = update_document(@document,@sanitized_params)
      @document.save
    end
  end
  
  
  protected

  # This is called in the before filter to validate all actions
  # The validation method is "#{action_name}_validation".  It should return true or false
  # def validate_workflow_step
  #   action = "#{params[:action]}_validation".to_sym
  #   if self.respond_to?(action) and self.send(action) === false
  #     redirect_to :back
  #   end
  # end

  # validate the author action
  # The first author requires an ID field.
  # All authors require a First & Last name.
  def contributor_validation
    i = 0
    desc_metadata = params[:asset][:descMetadata]
    while desc_metadata.has_key? "person_#{i}_computing_id".to_sym
      if i == 0 and desc_metadata[:person_0_computing_id]["0"].blank?
        #flash[:error] = "The ID for the first author must be filled in."
        #return false 
      end
      if desc_metadata["person_#{i}_first_name".to_sym]["0"].blank? or desc_metadata["person_#{i}_last_name".to_sym]["0"].blank?
        flash[:error] = "The First and Last names are required for all authors."
        return false
      end
      i += 1
    end
    return true
  end
  
  def publication_validation
    desc_metadata = params[:asset][:descMetadata]
    if desc_metadata[:title_info_main_title]["0"].blank? or desc_metadata[:journal_0_title_info_main_title]["0"].blank?
      flash[:error] = "The title fields are required."
      return false
    else
      return true
    end
  end
  
  def additional_info_validation
    rights_metadata = params[:asset][:rightsMetadata]
    if rights_metadata[:embargo_embargo_release_date]["0"].blank?
      flash[:error] = "You must enter a release date"
      return false
    end
    return true
  end
  
  # def enforce_edit
  #   redirect_to root unless editor?
  # end
  
end