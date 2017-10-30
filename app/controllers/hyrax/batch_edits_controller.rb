module Hyrax
  class BatchEditsController < ApplicationController
    include FileSetHelper
    include Hyrax::Breadcrumbs
    include Hyrax::Collections::AcceptsBatches

    before_action :build_breadcrumbs, only: :edit
    before_action :filter_docs_with_access!, only: [:edit, :update, :destroy_collection]
    before_action :check_for_empty!, only: [:edit, :update, :destroy_collection]

    # provides the help_text view method
    helper PermissionsHelper

    class_attribute :resource_class, :change_set_class, :change_set_persister
    self.resource_class = Hyrax.primary_work_type
    self.change_set_class = BatchEditChangeSet
    self.change_set_persister = Hyrax::ChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie.config.storage_adapter
    )

    def edit
      work = resource_class.new
      work.depositor = current_user.user_key
      @change_set = change_set_class.new(work, batch_document_ids: batch).prepopulate!
    end

    def after_update
      respond_to do |format|
        format.json { head :no_content }
        format.html { redirect_to_return_controller }
      end
    end

    def after_destroy_collection
      redirect_to_return_controller unless request.xhr?
    end

    def check_for_empty!
      return unless check_for_empty_batch?
      redirect_back fallback_location: hyrax.batch_edits_path
      false
    end

    def destroy_collection
      destroy_batch
      flash[:notice] = "Batch delete complete"
      after_destroy_collection
    end

    def update_document(obj)
      change_set = change_set_class.new(obj)
      if change_set.validate(resource_params.merge(visibility: params[:visibility]))
        change_set.sync
        change_set_persister.buffer_into_index do |persist|
          persist.save(change_set: change_set)
        end
      else
        logger.error("Unable to update #{obj.id} in a batch update #{change_set.errors.full_messages}")
      end
    end

    def update
      case params["update_type"]
      when "update"
        batch.each do |doc_id|
          update_document(find_resource(doc_id))
        end
        flash[:notice] = "Batch update complete"
        after_update
      when "delete_all"
        destroy_batch
        after_update
      end
    end

    private

      def add_breadcrumb_for_controller
        add_breadcrumb I18n.t('hyrax.dashboard.my.works'), hyrax.my_works_path
      end

      def _prefixes
        # This allows us to use the templates in hyrax/base, while prefering
        # our local paths. Thus we are unable to just override `self.local_prefixes`
        @_prefixes ||= super + ['hyrax/base']
      end

      def destroy_batch
        batch.each { |id| persister.delete(resource: find_resource(id)) }
      end

      def terms
        change_set_class.terms
      end

      def resource_params
        raw_params = params[resource_class.model_name.param_key]
        raw_params ? raw_params.to_unsafe_h : {}
      end

      def redirect_to_return_controller
        if params[:return_controller]
          redirect_to hyrax.url_for(controller: params[:return_controller], only_path: true)
        else
          redirect_to hyrax.dashboard_path
        end
      end

      def find_resource(id)
        query_service.find_by(id: Valkyrie::ID.new(id.to_s))
      end

      def adapter
        Valkyrie::MetadataAdapter.find(:indexing_persister)
      end
      delegate :query_service, :persister, to: :adapter
  end
end
