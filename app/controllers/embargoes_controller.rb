class EmbargoesController < ApplicationController

  include Worthwhile::WithoutNamespace
  include Worthwhile::ManagesEmbargoes

  def destroy
    curation_concern.deactivate_embargo!
    curation_concern.save
    flash[:notice] = curation_concern.embargo_history.last
    redirect_to edit_embargo_path(curation_concern)
  end

  protected
    def _prefixes
      # This allows us to use the unauthorized template in curation_concern/base
      @_prefixes ||= super + ['curation_concern/base']
    end
end
