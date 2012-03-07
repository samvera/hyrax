require 'mediashelf/active_fedora_helper'
class Hydra::PermissionsController < ApplicationController
  include MediaShelf::ActiveFedoraHelper
  include Hydra::AssetsControllerHelper
  
  before_filter :require_solr
  # need to include this after the :require_solr before_filter because of the before filter that the workflow provides.
  include Hydra::SubmissionWorkflow
  
  def index
    af_base=ActiveFedora::Base.load_instance(params[:asset_id])
    the_model = ActiveFedora::ContentModel.known_models_for( af_base ).first
    @document_fedora = af_base.adapt_to(the_model)
    
    respond_to do |format|
      format.html 
      format.inline { render :partial=>"hydra/permissions/index", :format=>"html" }
    end
  end
  
  def new
    respond_to do |format|
      format.html 
      format.inline { render :partial=>"hydra/permissions/new" }
    end
  end
  
  def edit
    af_base=ActiveFedora::Base.load_instance(params[:asset_id])
    the_model = ActiveFedora::ContentModel.known_models_for( af_base ).first
    @document_fedora = af_base.adapt_to(the_model)
    
    respond_to do |format|
      format.html 
      format.inline {render :action=>"edit", :layout=>false}
    end
  end
  
  # Create a new permissions entry
  # expects permission["actor_id"], permission["actor_type"] and permission["access_level"] as params. ie.   :permission=>{"actor_id"=>"_person_id_","actor_type"=>"person","access_level"=>"read"}
  def create
    @document_fedora=ActiveFedora::Base.find(params[:asset_id])

    access_actor_type = params["permission"]["actor_type"]
    actor_id = params["permission"]["actor_id"]
    access_level = params["permission"]["access_level"]
  
    # update the datastream's values
    result = @document_fedora.rightsMetadata.permissions({access_actor_type => actor_id}, access_level)
    @document_fedora.save
    
    flash[:notice] = "#{actor_id} has been granted #{access_level} permissions for #{params[:asset_id]}"
    
    respond_to do |format|
      format.html do 
        if params.has_key?(:add_permission)
          redirect_to :back
        else
          redirect_to next_step(params[:asset_id])
        end
        
      end
      format.inline { render :partial=>"hydra/permissions/edit_person_permissions", :locals=>{:person_id=>actor_id}}
    end

  end
  
  # Updates the permissions for all actors in a hash.  Can specify as many groups and persons as you want
  # ie. :permission => {"group"=>{"group1"=>"discover","group2"=>"edit"}, {"person"=>{"person1"=>"read"}}}
  def update
    if params[:id].nil?  
      pid = params[:asset_id]
    else
      pid = params[:id]
    end
    
    @document_fedora=ActiveFedora::Base.find(pid)

    # update the datastream's values
    result = @document_fedora.rightsMetadata.update_permissions(params[:permission])
    
    @document_fedora.save
    
    
    flash[:notice] = "The permissions have been updated."
    
    respond_to do |format|
      format.html do
        if params.has_key?(:add_permission)
          redirect_to edit_catalog_path(pid, :wf_step => :permissions, :add_permission => true)
        else
          redirect_to next_step(pid)
        end
      end
      format.inline do
        # This should be replaced ...
        if params[:permission].has_key?(:group)
          access_actor_type = "group"
        else
          access_actor_type = "person"
        end
        actor_id = params["permission"][access_actor_type].first[0]
        render :partial=>"hydra/permissions/edit_person_permissions", :locals=>{:person_id=>actor_id} 
      end
    end
    
  end
    
end
