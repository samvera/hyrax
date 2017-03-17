module Hyrax
  module BatchUploadsControllerBehavior
    extend ActiveSupport::Concern
    include Hydra::Controller::ControllerBehavior
    include Hyrax::CurationConcernController

    included do
      self.work_form_service = BatchUploadFormService
      self.curation_concern_type = work_form_service.form_class.model_class # includes CanCan side-effects
      # We use BatchUploadItem as a null stand-in curation_concern_type.
      # The actual permission is checked dynamically during #create.
    end

    # The permissions to create a batch are not as important as the permissions for the concern being batched.
    # @note we don't call `authorize!` directly, since `authorized_models` already checks `user.can? :create, ...`
    def create
      authenticate_user!
      unsafe_pc = params.fetch(:batch_upload_item, {})[:payload_concern]
      # Calling constantize on user params is disfavored (per brakeman), so we sanitize by matching it against an authorized model.
      safe_pc = Hyrax::SelectTypeListPresenter.new(current_user).authorized_models.map(&:to_s).find { |x| x == unsafe_pc }
      raise CanCan::AccessDenied, "Cannot create an object of class '#{unsafe_pc}'" unless safe_pc
      # authorize! :create, safe_pc
      create_update_job(safe_pc)
      # Calling `#t` in a controller context does not mark _html keys as html_safe
      flash[:notice] = view_context.t('hyrax.works.create.after_create_html', application_name: view_context.application_name)
      redirect_after_update
    end

    # Gives the class of the form.
    class BatchUploadFormService < Hyrax::WorkFormService
      def self.form_class(_ = nil)
        ::Hyrax::Forms::BatchUploadForm
      end
    end

    protected

      def build_form
        super
        @form.payload_concern = params[:payload_concern]
      end

      def redirect_after_update
        if uploading_on_behalf_of?
          redirect_to hyrax.dashboard_shares_path
        else
          redirect_to hyrax.dashboard_works_path
        end
      end

      # @param [String] klass the name of the Hyrax Work Class being created by the batch
      # @note Cannot use a proper Class here because it won't serialize
      def create_update_job(klass)
        operation = BatchCreateOperation.create!(user: current_user,
                                                 operation_type: "Batch Create")
        # ActionController::Parameters are not serializable, so cast to a hash
        BatchCreateJob.perform_later(current_user,
                                     params[:title].permit!.to_h,
                                     params.fetch(:resource_type, {}).permit!.to_h,
                                     params[:uploaded_files],
                                     attributes_for_actor.to_h.merge!(model: klass),
                                     operation)
      end

      def uploading_on_behalf_of?
        params.fetch(hash_key_for_curation_concern).key?(:on_behalf_of)
      end
  end
end
