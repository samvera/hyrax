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

    def edit
      work = form_class.model_class.new
      work.depositor = current_user.user_key
      @form = form_class.new(work, current_user, batch)
    end

    def after_update
      respond_to do |format|
        format.json { head :no_content }
        format.html { redirect_to_return_controller }
      end
    end

    def after_destroy_collection
      redirect_back fallback_location: hyrax.batch_edits_path
    end

    def check_for_empty!
      return unless check_for_empty_batch?
      redirect_back fallback_location: hyrax.batch_edits_path
      false
    end

    def destroy_collection
      batch.each do |doc_id|
        obj = ActiveFedora::Base.find(doc_id, cast: true)
        obj.destroy
      end
      flash[:notice] = "Batch delete complete"
      after_destroy_collection
    end

    def update_document(obj)
      obj.attributes = work_params
      obj.date_modified = Time.current.ctime
      obj.visibility = params[:visibility]
      obj.save
    end

    def update
      case params["update_type"]
      when "update"
        batch.each do |doc_id|
          update_document(ActiveFedora::Base.find(doc_id))
        end
        flash[:notice] = "Batch update complete"
        after_update
      when "delete_all"
        destroy_batch
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
        batch.each { |id| ActiveFedora::Base.find(id).destroy }
        after_update
      end

      def form_class
        Forms::BatchEditForm
      end

      def terms
        form_class.terms
      end

      def work_params
        work_params = params[form_class.model_name.param_key] || ActionController::Parameters.new
        form_class.model_attributes(work_params)
      end

      def redirect_to_return_controller
        if params[:return_controller]
          redirect_to hyrax.url_for(controller: params[:return_controller], only_path: true)
        else
          redirect_to hyrax.dashboard_path
        end
      end
  end
end
