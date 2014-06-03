class LeasesController < ApplicationController
  include Worthwhile::ManagesEmbargoes

  def destroy
    curation_concern.deactivate_lease!
    curation_concern.save
    flash[:notice] = curation_concern.lease_history.last
    redirect_to edit_lease_path(curation_concern)
  end
end