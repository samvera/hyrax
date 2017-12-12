module Hyrax
  class EmbargoesController < ApplicationController
    include Hyrax::Collections::AcceptsBatches

    def index
      authorize! :index, Hydra::AccessControls::Embargo
    end

    def edit
      work = find_resource(params[:id])
      authorize! :edit, work
      @resource = find_resource(work.embargo_id)
      @change_set = EmbargoChangeSet.new(@resource, parent_resource: work)
    end

    # Removes a single embargo
    def destroy
      work = find_resource(params[:id])
      authorize! :destroy, work
      embargo = Hyrax::Actors::EmbargoActor.new(work).destroy
      flash[:notice] = embargo.embargo_history.last
      if work.work? && work.file_sets.present?
        redirect_to confirm_permission_path
      else
        redirect_to edit_embargo_path
      end
    end

    # Updates a batch of embargos
    def update
      filter_docs_with_edit_access!
      copy_visibility = params[:embargoes].values.map { |h| h[:copy_visibility] }
      batch.each do |id|
        curation_concern = find_resource(id)
        Hyrax::Actors::EmbargoActor.new(curation_concern).destroy
        curation_concern.copy_visibility_to_files if copy_visibility.include?(id)
      end
      redirect_to embargoes_path
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
