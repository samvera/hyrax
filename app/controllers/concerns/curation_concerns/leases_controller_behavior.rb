module CurationConcerns
  module LeasesControllerBehavior
    extend ActiveSupport::Concern
    include CurationConcerns::ManagesEmbargoes
    include Hydra::Collections::AcceptsBatches

    included do
      skip_before_action :normalize_identifier, only: :update
    end

    def index
      authorize! :discover, Hydra::AccessControls::Lease
    end

    def destroy
      LeaseActor.new(curation_concern).destroy
      flash[:notice] = curation_concern.lease_history.last
      if curation_concern.works_generic_work? && curation_concern.generic_files.present?
        redirect_to confirm_curation_concerns_permission_path(curation_concern)
      else
        redirect_to edit_lease_path(curation_concern)
      end
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
end
