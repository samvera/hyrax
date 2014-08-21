class EmbargoesController < ApplicationController

  include Worthwhile::WithoutNamespace
  include Worthwhile::ManagesEmbargoes
  include Hydra::Collections::AcceptsBatches

  skip_before_filter :normalize_identifier, only: :update

  def destroy
    remove_embargo(curation_concern)
    flash[:notice] = curation_concern.embargo_history.last
    redirect_to edit_embargo_path(curation_concern)
  end

  def update
    filter_docs_with_edit_access!
    batch.each do |id|
      ActiveFedora::Base.find(id).tap do |curation_concern|
        remove_embargo(curation_concern)
      end
    end
    redirect_to embargoes_path
  end

  protected
    def _prefixes
      # This allows us to use the unauthorized template in curation_concern/base
      @_prefixes ||= super + ['curation_concern/base']
    end

    def remove_embargo(work)
      work.embargo_visibility! # If the embargo has lapsed, update the current visibility.
      work.deactivate_embargo!
      work.save
    end
end
