class LeasesController < ApplicationController
  include Worthwhile::WithoutNamespace
  include Worthwhile::ManagesEmbargoes

  def destroy
    curation_concern.deactivate_lease!
    curation_concern.save
    flash[:notice] = curation_concern.lease_history.last
    redirect_to edit_lease_path(curation_concern)
  end

  protected
    def _prefixes
      # This allows us to use the unauthorized template in curation_concern/base
      @_prefixes ||= super + ['curation_concern/base']
    end
end
