class CurationConcerns::PermissionsController < ApplicationController
  include CurationConcerns::CurationConcernController
  with_themed_layout '1_column'

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
