class BatchController < ApplicationController
  include Hydra::Controller::ControllerBehavior
  include Hydra::AssetsControllerHelper  # for apply_depositor_metadata method
  include Hydra::Controller::UploadBehavior
  include ScholarSphere::Noid # for normalize_identifier method

  prepend_before_filter :normalize_identifier, :only=>[:edit, :show, :update, :destroy]

  def edit
    @batch =  Batch.find_or_create(params[:id])
    @generic_file = GenericFile.new
    @generic_file.title =  @batch.generic_files.map{ |gf| gf.label }.join(', ')
    @generic_file.creator = current_user.name
    begin
      @groups = current_user.groups
    rescue
      logger.warn "Can not get to LDAP for user groups"
    end
  end

  def update
    batch = Batch.find_or_create(params[:id])
    notice = []
    ScholarSphere::GenericFile::Permissions.parse_permissions(params)
    authenticate_user!
    fSaved = []
    fDenied = []
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
        fSaved << gf
      else
        fDenied << gf
      end
    end
    logger.info ("********  save files = #{fSaved.inspect}")
    notice << render_to_string(:partial=>'generic_files/asset_saved_flash', :locals => { :generic_files => fSaved }) if (fSaved.length > 0)
    notice << render_to_string(:partial=>'generic_files/asset_permissions_denial_flash', :locals => { :generic_files => fDenied }) if (fDenied.length > 0)
    flash[:notice] = notice.join("<br/>".html_safe) unless notice.blank?
    redirect_to dashboard_path
  end
end
