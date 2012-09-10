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

    flash[:notice] = 'Your files are being processed by ScholarSphere in the background. The metadata and access controls you specified are being applied. Files will be marked <span class="label label-important" title="Private">Private</span> until this process is complete (shouldn\'t take too long, hang in there!). You may need to refresh your dashboard to see these updates.'
    redirect_to dashboard_path
  end
end
