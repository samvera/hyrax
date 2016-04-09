# TODO: Replace this with something that has lower technical debt
# This controller is only needed because we override the layout that
# CurationConcerns sets for it, to pick up Sufia's layout. We should
# be able to remove this controller once we have updated CC to allow
# for the layout to be configured. See here for more discussion:
# https://github.com/projecthydra/sufia/issues/1731#issuecomment-206597463
class CurationConcerns::PermissionsController < ApplicationController
  include CurationConcerns::CurationConcernController

  layout nil

  def confirm
  end

  def copy
    authorize! :edit, curation_concern
    VisibilityCopyJob.perform_later(curation_concern)
    flash_message = 'Updating file permissions. This may take a few minutes. You may want to refresh your browser or return to this record later to see the updated file permissions.'
    redirect_to [main_app, curation_concern], notice: flash_message
  end

  def curation_concern
    @curation_concern ||= ActiveFedora::Base.find(params[:id])
  end
end
