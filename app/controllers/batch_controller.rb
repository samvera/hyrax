require "psu-customizations"
class BatchController < ApplicationController
  
  include Hydra::Controller
  include Hydra::AssetsControllerHelper  # This is to get apply_depositor_metadata method
  include Hydra::FileAssetsHelper
  include PSU::Noid

  prepend_before_filter :normalize_identifier, :only=>[:edit, :show, :update, :destroy] 

  def edit
    @batch = Batch.new({pid: params[:id]})
    @generic_file = GenericFile.new 
  end
  
  def update
    batch = Batch.find_or_create(params[:id])
    notice = []
    Scholarsphere::GenericFile::Permissions.parse_permissions(params)
    authenticate_user!
    batch.generic_files.each do |gf|
      #todo check metadata not push...
      #if (can read)      
      if can? :read, permissions_solr_doc_for_id(gf.pid)
      
        if params.has_key?(:permission)
          gf.datastreams["rightsMetadata"].permissions({:group=>"public"}, params[:permission][:group][:public])
        else
          gf.datastreams["rightsMetadata"].permissions({:group=>"public"}, "none")
        end
        gf.update_attributes(params[:generic_file])
        gf.save
        notice << render_to_string(:partial=>'generic_files/asset_saved_flash', :locals => { :generic_file => gf })
      else
        notice << render_to_string(:partial=>'generic_files/asset_permissions_denial_flash', :locals => { :generic_file => gf })
      end
      flash[:notice] = notice.join("<br/>".html_safe) unless notice.blank?
    end
    redirect_to dashboard_path
  end
 
  protected
  def normalize_identifier
    params[:id] = "#{ScholarSphere::Application.config.id_namespace}:#{params[:id]}" unless params[:id].start_with? ScholarSphere::Application.config.id_namespace
  end
  
  # Returns the solr permissions document for the given id
  # @return solr permissions document  
  # @example This is the document that you can pass into permissions enforcement methods like 'can?'
  #   gf = GenericFile.find(params[:id])
  #   if can? :read, permissions_solr_doc_for_id(gf.pid)
  #     gf.update_attributes(params[:generic_file])
  #   end
  def permissions_solr_doc_for_id(id)
    permissions_solr_response, permissions_solr_document = get_permissions_solr_response_for_doc_id(id)
    return permissions_solr_document
  end

end
