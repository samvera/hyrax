module Hyrax
  module LeasesControllerBehavior
    extend ActiveSupport::Concern
    include Hyrax::ManagesEmbargoes
    include Hyrax::Collections::AcceptsBatches

    def index
      authorize! :index, Hydra::AccessControls::Lease
    end

    # Removes a single lease
    def destroy
      @curation_concern = find_resource(params[:id])
      authorize! :destroy, @curation_concern
      Hyrax::Actors::LeaseActor.new(@curation_concern).destroy
      flash[:notice] = @curation_concern.lease_history.last
      if @curation_concern.work? && @curation_concern.file_sets.present?
        redirect_to confirm_permission_path
      else
        redirect_to edit_lease_path
      end
    end

    def update
      filter_docs_with_edit_access!
      copy_visibility = params[:leases].values.map { |h| h[:copy_visibility] }
      batch.each do |id|
        curation_concern = find_resource(id)
        Hyrax::Actors::LeaseActor.new(curation_concern).destroy
        curation_concern.copy_visibility_to_files if copy_visibility.include?(id)
      end
      redirect_to leases_path
    end

    # This allows us to use the unauthorized template in curation_concerns/base
    def self.local_prefixes
      ['hyrax/base']
    end
  end
end
