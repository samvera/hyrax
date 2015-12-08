module CurationConcerns
  module UploadSetsControllerBehavior
    extend ActiveSupport::Concern
    include Hydra::Controller::ControllerBehavior

    included do
      include CurationConcerns::ThemedLayoutController
      with_themed_layout '1_column'

      class_attribute :edit_form_class
      self.edit_form_class = CurationConcerns::GenericWorkForm
    end

    def edit
      @upload_set = UploadSet.find_or_create(params[:id])
      @form = edit_form
    end

    def update
      authenticate_user!
      @upload_set = UploadSet.find_or_create(params[:id])
      @upload_set.status = ["processing"]
      @upload_set.save
      create_update_job
      flash[:notice] = 'Your files are being processed by ' + t('curation_concerns.product_name') + ' in the background. The metadata and access controls you specified are being applied. Files will be marked <span class="label label-danger" title="Private">Private</span> until this process is complete (shouldn\'t take too long, hang in there!). You may need to refresh your dashboard to see these updates.'

      redirect_to main_app.curation_concerns_generic_works_path
    end

    protected

      def edit_form
        # TODO: instead of using GenericWorkForm, this should be an UploadSetForm
        titles = @upload_set.works.map { |w| w.title.first }
        work = ::GenericWork.new(creator: [current_user.user_key], title: titles)
        edit_form_class.new(work, current_ability)
      end

      def create_update_job
        UploadSetUpdateJob.perform_later(current_user.user_key,
                                         params[:id],
                                         params[:title],
                                         edit_form_class.model_attributes(params[:work]),
                                         params[:visibility])
      end
  end
end
