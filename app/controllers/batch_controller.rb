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
    if params.has_key?(:permission)
      if params[:permission][:group][:public] == 'read'
        if params[:generic_file][:read_groups_string].present?
          params[:generic_file][:read_groups_string] << ', public'
        else 
          params[:generic_file][:read_groups_string] << 'public'
        end
      elsif params[:permission][:group][:public] == 'discover'
        params[:generic_file][:discover_groups_string] = 'public'
      end
    end
    batch.generic_files.each do |gf|
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
