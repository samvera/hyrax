class LeasesController < ApplicationController
  include Worthwhile::ThemedLayoutController
  with_themed_layout '1_column'

  include Worthwhile::ManagesEmbargoes
  attr_accessor :curation_concern
  helper_method :curation_concern
  helper_method :assets_under_lease, :assets_with_expired_leases, :assets_with_deactivated_leases
  load_and_authorize_resource class: ActiveFedora::Base, instance_name: :curation_concern

  def index
  end

  def edit
  end

  def destroy
    curation_concern.deactivate_lease!
    curation_concern.save
    flash[:notice] = curation_concern.lease_history.last
    redirect_to edit_lease_path(curation_concern)
  end
end