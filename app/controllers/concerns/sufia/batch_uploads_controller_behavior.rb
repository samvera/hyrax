module Sufia
  module BatchUploadsControllerBehavior
    extend ActiveSupport::Concern
    include Hydra::Controller::ControllerBehavior
    include CurationConcerns::CurationConcernController

    included do
      self.work_form_service = BatchUploadFormService
      self.curation_concern_type = work_form_service.form_class.model_class
    end

    def create
      authenticate_user!
      create_update_job
      flash[:notice] = t('sufia.works.new.after_create_html', application_name: view_context.application_name)
      redirect_after_update
    end

    # Gives the class of the form.
    class BatchUploadFormService < CurationConcerns::WorkFormService
      def self.form_class(_ = nil)
        ::Sufia::Forms::BatchUploadForm
      end
    end

    protected

      def redirect_after_update
        if uploading_on_behalf_of?
          redirect_to sufia.dashboard_shares_path
        else
          redirect_to sufia.dashboard_works_path
        end
      end

      def create_update_job
        log = BatchCreateOperation.create!(user: current_user,
                                           operation_type: "Batch Create")
        # ActionController::Parameters are not serializable, so cast to a hash
        BatchCreateJob.perform_later(current_user,
                                     params[:title].permit!.to_h,
                                     params[:resource_type].permit!.to_h,
                                     params[:uploaded_files],
                                     attributes_for_actor.to_h,
                                     log)
      end

      def uploading_on_behalf_of?
        params.fetch(hash_key_for_curation_concern).key?(:on_behalf_of)
      end
  end
end
