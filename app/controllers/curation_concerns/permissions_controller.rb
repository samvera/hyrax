class CurationConcerns::PermissionsController < ApplicationController
  include CurationConcerns::PermissionsControllerBehavior

  def confirm_access
    # intentional noop to display default rails view
  end

  def copy_access
    authorize! :edit, curation_concern
    # copy visibility
    VisibilityCopyJob.perform_later(curation_concern)

    # copy permissions
    InheritPermissionsJob.perform_later(curation_concern)
    redirect_to [main_app, curation_concern], notice: I18n.t("sufia.upload.change_access_flash_message")
  end
end
