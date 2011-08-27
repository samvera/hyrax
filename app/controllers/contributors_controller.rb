require 'mediashelf/active_fedora_helper'

class ContributorsController < ApplicationController
  
  include MediaShelf::ActiveFedoraHelper
  include Hydra::RepositoryController
  include Hydra::AssetsControllerHelper
  before_filter :require_solr, :require_fedora
  
  # need to include this after the :require_solr/fedora before filters because of the before filter that the workflow provides.
  include Hydra::SubmissionWorkflow
  
  # Display form for adding a new Contributor
  # If contributor_type is provided, renders the appropriate "new" form
  # If contributor_type is not provided, renders a form for selecting which type of contributor to add
  # If format is .inline, this renders without layout so you can embed it in a page
  def new
    
    # Only load the document if you need to
    if params.has_key?(:contributor_type) 
      @document_fedora = load_document_from_id(params[:asset_id])
      @next_contributor_index = @document_fedora
    end
    
    respond_to do |format|
      format.html { render :file=>"contributors/new.html" , :layout=>true}
      format.inline { render :partial=>"contributors/new.html", :layout=>false }
    end
  end
  
  def create
    @document_fedora = load_document_from_id(params[:asset_id])
    
    ct = params[:contributor_type]
    inserted_node, new_node_index = @document_fedora.insert_contributor(ct)
    @document_fedora.save
    partial_name = "contributors/edit_#{ct}.html"
    respond_to do |format|
      format.html { redirect_to( url_for(:controller=>"catalog", :action=>"edit", :id=>params[:asset_id] )+"##{params[:contributor_type]}_#{new_node_index}" ) }
      format.inline { render :partial=>partial_name, :locals=>{"edit_#{ct}".to_sym =>inserted_node, "edit_#{ct}_counter".to_sym =>new_node_index}, :layout=>false }
    end
    
  end
  
  # Not sure how the #create method was intended to work, but this seems like it works and takes a hybrid approach to how the contributors were handled between this and the AssetsController work.
  def update
    @document = load_document_from_params
    # generates sanatized params from params hash to update the doc with
    sanitize_update_params
    @response = update_document(@document,@sanitized_params)
    @document.save
    flash[:notice] = "Your changes have been saved."
    if params.has_key? :add_another_author
      redirect_to({:controller => "catalog", :action => "edit", :id => params[:id], :wf_step => :contributor, :add_contributor => true}) 
    else
      redirect_to( {:controller => "catalog", :action => "edit", :id => params[:id]}.merge(params_for_next_step_in_wokflow) )
    end
  end
  
  def destroy
    af_model = retrieve_af_model(params[:content_type], :default=>ModsAsset)
    @document_fedora = af_model.find(params[:id])
    @document_fedora.remove_contributor(params[:contributor_type], params[:index])
    result = @document_fedora.save
    if request.xhr?
      render :text=>result.inspect
    else
      redirect_to({:controller => "catalog", :action => "edit", :id => params[:id], :wf_step => :contributor})
    end
  end
  
  protected 
  
  # validate the mods assets when they are sumbitted
  # The first author requires an ID field.
  # All authors require a First & Last name.
  def mods_assets_update_validation
    i = 0
    desc_metadata = params[:asset][:descMetadata]
    unless desc_metadata.nil?
      while desc_metadata.has_key? "person_#{i}_computing_id".to_sym
        if desc_metadata["person_#{i}_first_name".to_sym]["0"].blank? or desc_metadata["person_#{i}_last_name".to_sym]["0"].blank?
          flash[:error] = "The First and Last names are required for all authors."
          return false
        end
        i += 1
      end
    end
    return true
  end
  
  private
  
  def load_document_from_id(asset_id)
    af_model = retrieve_af_model(params[:content_type], :default=>ModsAsset)
    af_model.find(asset_id)
  end
  
end