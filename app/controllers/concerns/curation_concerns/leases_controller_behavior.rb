module CurationConcerns
  module LeasesControllerBehavior
    extend ActiveSupport::Concern
    include CurationConcerns::ManagesEmbargoes
    include Hydra::Collections::AcceptsBatches

    included do
      skip_before_action :normalize_identifier, only: :update
    end

    def index
      authorize! :index, Hydra::AccessControls::Lease
    end

    # Removes a single lease
    def destroy
      LeaseActor.new(curation_concern).destroy
      flash[:notice] = curation_concern.lease_history.last
      if curation_concern.work? && curation_concern.file_sets.present?
        redirect_to confirm_curation_concerns_permission_path(curation_concern)
      else
        redirect_to edit_lease_path(curation_concern)
      end
    end

    def update
      filter_docs_with_edit_access!
      copy_visibility = params[:leases].values.map { |h| h[:copy_visibility] }
      ActiveFedora::Base.find(batch).each do |curation_concern|
        LeaseActor.new(curation_concern).destroy
        curation_concern.copy_visibility_to_files if copy_visibility.include?(curation_concern.id)
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
