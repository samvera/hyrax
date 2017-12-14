module Hyrax
  class LeasesController < ApplicationController
    include Hyrax::Collections::AcceptsBatches

    def index
      authorize! :index, Hydra::AccessControls::Lease
    end

    def edit
      work = find_resource(params[:id])
      authorize! :edit, work
      @resource = find_resource(work.lease_id)
      @change_set = LeaseChangeSet.new(@resource, parent_resource: work)
    end

    # Removes a single lease
    def destroy
      curation_concern = find_resource(params[:id])
      authorize! :destroy, curation_concern
      lease = Hyrax::Actors::LeaseActor.new(curation_concern).destroy
      flash[:notice] = lease.lease_history.last
      if curation_concern.work? && curation_concern.file_sets.present?
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

    private

      def find_resource(id)
        query_service.find_by(id: Valkyrie::ID.new(id.to_s))
      end

      def query_service
        Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
      end

      # This is an override of Hyrax::ApplicationController
      def deny_access(exception)
        redirect_to root_path, alert: exception.message
      end
  end
end
