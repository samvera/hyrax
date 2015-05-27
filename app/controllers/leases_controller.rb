class LeasesController < ApplicationController
  include CurationConcerns::ManagesEmbargoes
  include Hydra::Collections::AcceptsBatches

  skip_before_filter :normalize_identifier, only: :update

  def destroy
    curation_concern.lease_visibility! # If the lease has lapsed, update the current visibility.
    curation_concern.deactivate_lease!
    saved = curation_concern.save
    Sufia.queue.push(VisibilityCopyWorker.new(curation_concern.id)) if saved
    flash[:notice] = curation_concern.lease_history.last
    redirect_to edit_lease_path(curation_concern)
  end

  def update
    filter_docs_with_edit_access!
    batch.each do |id|
      ActiveFedora::Base.find(id).tap do |curation_concern|
        curation_concern.deactivate_lease!
        curation_concern.save
      end
    end
    redirect_to leases_path
  end


  protected
    def _prefixes
      # This allows us to use the unauthorized template in curation_concerns/base
      @_prefixes ||= super + ['curation_concerns/base']
    end
end
