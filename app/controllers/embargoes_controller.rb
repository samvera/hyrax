class EmbargoesController < ApplicationController
  include Worthwhile::ThemedLayoutController
  with_themed_layout '1_column'

  include Worthwhile::ManagesEmbargoes
  attr_accessor :curation_concern
  helper_method :curation_concern
  helper_method :assets_under_embargo, :assets_with_expired_embargoes, :assets_with_deactivated_embargoes
  load_and_authorize_resource class: ActiveFedora::Base, instance_name: :curation_concern

  def index
  end

  def edit
  end

  def destroy
    curation_concern.deactivate_embargo!
    curation_concern.save
    flash[:notice] = curation_concern.embargo_history.last
    redirect_to edit_embargo_path(curation_concern)
  end


end