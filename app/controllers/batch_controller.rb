require "psu-customizations"
class BatchController < ApplicationController
  
  include Hydra::Controller
  include Hydra::AssetsControllerHelper  # This is to get apply_depositor_metadata method
  include Hydra::FileAssetsHelper
  include PSU::Noid

  prepend_before_filter :normalize_identifier, :only=>[:edit, :show, :update, :destroy] 
#  before_filter :enforce_access_controls, :only=>[:edit, :update]

  def edit
    @batch = Batch.new({pid: params[:id]})
    @generic_file = GenericFile.new 
  end
  
  def update
    batch = Batch.find_or_create(params[:id])
    notice = []
    Scholarsphere::GenericFile::Permissions.parse_permissions(params)
    batch.generic_files.each do |gf|
      #todo check metadata not push...
      #if (can read)      

      if params.has_key?(:permission)
        gf.datastreams["rightsMetadata"].permissions({:group=>"public"}, params[:permission][:group][:public])
      else
        gf.datastreams["rightsMetadata"].permissions({:group=>"public"}, "none")
      end

      gf.update_attributes(params[:generic_file])
      gf.save
      notice << render_to_string(:partial=>'generic_files/asset_saved_flash', :locals => { :generic_file => gf })
      #else
      #notice << render_to_string(:partial=>'generic_files/asset_permission_issue_flash', :locals => { :generic_file => gf })
    end
    flash[:notice] = notice.join("<br/>".html_safe) unless notice.blank?
    redirect_to dashboard_path
  end
end
