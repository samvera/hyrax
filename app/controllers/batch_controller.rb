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
    ScholarSphere::GenericFile::Permissions.parse_permissions(params)
    authenticate_user!
    Resque.enqueue(BatchUpdateJob, current_user.login, params)

    flash[:notice] = "Files are being processessed by ScholarSphere the permissions, and the metadata you added is being applied. This should only take a couple minutes."
    redirect_to dashboard_path
  end
end
