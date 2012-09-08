class BatchController < ApplicationController
  include Hydra::Controller::ControllerBehavior
  include Hydra::AssetsControllerHelper  # for apply_depositor_metadata method
  include Hydra::Controller::UploadBehavior
  include ScholarSphere::Noid # for normalize_identifier method

  before_filter :has_access?
  prepend_before_filter :normalize_identifier, :only=>[:edit, :show, :update, :destroy]

  def edit
    @batch =  Batch.find_or_create(params[:id])
    @generic_file = GenericFile.new
    @generic_file.creator = current_user.name
    @generic_file.title =  @batch.generic_files.map(&:label)
    begin
      @groups = current_user.groups
    rescue
      logger.warn "Can not get to LDAP for user groups"
    end
  end

  def update
    #notice = []
    ScholarSphere::GenericFile::Permissions.parse_permissions(params)
    authenticate_user!
    #Resque.enqueue(BatchUpdateJob, params[:id], params[:generic_file], current_user.login, params)
    Resque.enqueue(BatchUpdateJob, current_user.login, params)

#    saved = []
#    denied = []
#    batch.generic_files.each do |gf|
#      unless can? :read, permissions_solr_doc_for_id(gf.pid)
#        denied << gf
#        next
#      end
#
#      gf.title = params[:title][gf.pid] if params[:title][gf.pid] rescue gf.label 
#      gf.update_attributes(params[:generic_file])
#      gf.set_visibility(params)
#      gf.save
#      begin
#        Resque.enqueue(ContentUpdateEventJob, gf.pid, current_user.login)
#      rescue Redis::CannotConnectError
#        logger.error "Redis is down!"
#      end
#      saved << gf
#    end

#    notice << render_to_string(:partial=>'generic_files/asset_saved_flash', :locals => { :generic_files => saved }) unless saved.empty?
#    notice << render_to_string(:partial=>'generic_files/asset_permissions_denial_flash', :locals => { :generic_files => denied }) unless denied.empty?
#    flash[:notice] = notice.join("<br/>".html_safe) unless notice.blank?
    flash[:notice] = "Files are being processessed by the system and the metadata you added is being applied. This should be finished shortly."
    redirect_to dashboard_path
  end
end
