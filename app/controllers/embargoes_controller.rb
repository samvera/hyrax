class EmbargoesController < ApplicationController

  include Worthwhile::ManagesEmbargoes

  def destroy
    curation_concern.deactivate_embargo!
    curation_concern.save
    flash[:notice] = curation_concern.embargo_history.last
    redirect_to edit_embargo_path(curation_concern)
  end
end