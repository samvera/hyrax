module CurationConcerns
  module UploadSetsControllerBehavior
    extend ActiveSupport::Concern
    include Hydra::Controller::ControllerBehavior

    included do
      include CurationConcerns::ThemedLayoutController
      with_themed_layout '1_column'

      class_attribute :edit_form_class
      self.edit_form_class = CurationConcerns::UploadSetForm
    end

    def edit
      # TODO: redlock this line so that two processes don't attempt to create at the same time.
      @upload_set = UploadSet.find_or_create(params[:id])
      @form = edit_form
    end

    def update
      authenticate_user!
      @upload_set = UploadSet.find(params[:id])
      @upload_set.status = ["processing"]
      @upload_set.save
      create_update_job
      flash[:notice] = 'Your files are being processed by ' + t('curation_concerns.product_name') + ' in the background. The metadata and access controls you specified are being applied. Files will be marked <span class="label label-danger" title="Private">Private</span> until this process is complete (shouldn\'t take too long, hang in there!). You may need to refresh your dashboard to see these updates.'

      redirect_after_update
    end

    protected

      # Override this method if you want to go elsewhere
      def redirect_after_update
        redirect_to main_app.curation_concerns_generic_works_path
      end

      def edit_form
        edit_form_class.new(@upload_set, current_ability)
      end

      def create_update_job
        UploadSetUpdateJob.perform_later(current_user.user_key,
                                         params[:id],
                                         params[:title],
                                         edit_form_class.model_attributes(params[:upload_set]),
                                         params[:visibility])
      end
  end
end
