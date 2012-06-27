class BatchController < ApplicationController
  include ScholarSphere::Noid # for normalize_identifier method
  include Hydra::Controller
  include Hydra::AssetsControllerHelper  # for apply_depositor_metadata method
  include Hydra::FileAssetsHelper

  prepend_before_filter :normalize_identifier, :only=>[:edit, :show, :update, :destroy] 

  def edit
    @batch = Batch.new({pid: params[:id]})
    @generic_file = GenericFile.new 
  end
  
  def update
    batch = Batch.find_or_create(params[:id])
    notice = []
    ScholarSphere::GenericFile::Permissions.parse_permissions(params)
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
 
end
