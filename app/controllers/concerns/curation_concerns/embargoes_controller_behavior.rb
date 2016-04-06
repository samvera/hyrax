module CurationConcerns
  module EmbargoesControllerBehavior
    extend ActiveSupport::Concern
    include CurationConcerns::ManagesEmbargoes
    include CurationConcerns::Collections::AcceptsBatches

    included do
      skip_before_action :normalize_identifier, only: :update
    end

    def index
      authorize! :index, Hydra::AccessControls::Embargo
    end

    # Removes a single embargo
    def destroy
      EmbargoActor.new(curation_concern).destroy
      flash[:notice] = curation_concern.embargo_history.last
      if curation_concern.work? && curation_concern.file_sets.present?
        redirect_to confirm_curation_concerns_permission_path(curation_concern)
      else
        redirect_to edit_embargo_path(curation_concern)
      end
    end

    # Updates a batch of embargos
    def update
      filter_docs_with_edit_access!
      copy_visibility = params[:embargoes].values.map { |h| h[:copy_visibility] }
      ActiveFedora::Base.find(batch).each do |curation_concern|
        EmbargoActor.new(curation_concern).destroy
        curation_concern.copy_visibility_to_files if copy_visibility.include?(curation_concern.id)
      end
      redirect_to embargoes_path
    end

    protected

      def _prefixes
        # This allows us to use the unauthorized template in curation_concerns/base
        @_prefixes ||= super + ['curation_concerns/base']
      end
  end
end
