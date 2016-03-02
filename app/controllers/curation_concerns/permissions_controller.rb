class CurationConcerns::PermissionsController < ApplicationController
  include CurationConcerns::CurationConcernController

  # This controller is only needed because we to overwrite the layout
  # that CurationConcers sets for it. We should be able to remove this
  # controller once we have updated CC to allow for the layout to be
  # configured.
  layout nil

  self.curation_concern_type = ActiveFedora::Base

  def confirm
  end

  def copy
    VisibilityCopyJob.perform_later(curation_concern.id)
    flash_message = 'Updating file permissions. This may take a few minutes. You may want to refresh your browser or return to this record later to see the updated file permissions.'
    redirect_to [main_app, curation_concern], notice: flash_message
  end

  def curation_concern
    @curation_concern ||= curation_concern_type.find(params[:id], cast: true)
  end
end
