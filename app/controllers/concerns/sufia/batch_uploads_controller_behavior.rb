module Sufia
  module BatchUploadsControllerBehavior
    extend ActiveSupport::Concern
    include Hydra::Controller::ControllerBehavior
    include CurationConcerns::CurationConcernController

    included do
      self.curation_concern_type = form_class.model_class
    end

    def create
      authenticate_user!
      create_update_job
      flash[:notice] = t('sufia.works.new.after_create_html', application_name: view_context.application_name)
      redirect_after_update
    end

    module ClassMethods
      def form_class
        ::Sufia::Forms::BatchUploadForm
      end
    end

    protected

      # Gives the class of the form.
      # This overrides CurationConcerns
      def form_class
        self.class.form_class
      end

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
