class BatchController < ApplicationController
  
  include Hydra::Controller
  include Hydra::AssetsControllerHelper  # This is to get apply_depositor_metadata method
  include Hydra::FileAssetsHelper

  prepend_before_filter :normalize_identifier, :only=>[:edit, :show, :update, :destroy] 
  before_filter :enforce_access_controls, :only=>[:edit, :update]
  
  def edit
    @batch = Batch.find(params[:id])
    @generic_file = GenericFile.new 
  end

  def update
    batch = Batch.find(params[:id])
    notice = []
    batch.generic_files.each do |gf|
      if params.has_key?(:permission)
        gf.datastreams["rightsMetadata"].permissions({:group=>"public"}, params[:permission][:group][:public])
      else
        gf.datastreams["rightsMetadata"].permissions({:group=>"public"}, "none")
      end
      gf.update_attributes(params[:generic_file])
      gf.save
      notice << render_to_string(:partial=>'generic_files/asset_saved_flash', :locals => { :generic_file => gf })
    end
    flash[:notice] = notice.join("<br/>".html_safe) unless notice.blank?
    redirect_to dashboard_path
  end
 
  protected
  def normalize_identifier
    params[:id] = "#{ScholarSphere::Application.config.id_namespace}:#{params[:id]}" unless params[:id].start_with? ScholarSphere::Application.config.id_namespace
  end

end
