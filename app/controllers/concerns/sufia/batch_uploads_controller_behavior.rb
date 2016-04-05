module Sufia
  module BatchUploadsControllerBehavior
    extend ActiveSupport::Concern
    include Hydra::Controller::ControllerBehavior
    include CurationConcerns::CurationConcernController

    included do
      layout "sufia-one-column"

      self.curation_concern_type = GenericWork
      before_action :has_access?
    end

    def create
      authenticate_user!
      create_update_job
      flash[:notice] = <<-EOS.strip_heredoc.tr("\n", ' ')
        Your files are being processed by #{t('curation_concerns.product_name')} in
        the background. The metadata and access controls you specified are being applied.
        Files will be marked <span class="label label-danger" title="Private">Private</span>
        until this process is complete (shouldn't take too long, hang in there!). You may need
        to refresh your dashboard to see these updates.
      EOS

      redirect_after_update
    end

    protected

      # Gives the class of the form.
      # This overrides CurationConcerns
      def form_class
        Sufia::BatchUploadForm
      end

      def redirect_after_update
        if uploading_on_behalf_of?
          redirect_to sufia.dashboard_shares_path
        else
          redirect_to sufia.dashboard_works_path
        end
      end

      def create_update_job
        attrs = attributes_for_actor
        titles = params[:title]
        # TODO: when the form supports unique titles per file, we can remove this:
        titles ||= params[:uploaded_files].each_with_object({}) do |key, obj|
          obj[key] = attrs[:title]
        end

        BatchCreateJob.perform_later(current_user,
                                     titles,
                                     params[:uploaded_files],
                                     attributes_for_actor)
      end

      def uploading_on_behalf_of?
        params.fetch(hash_key_for_curation_concern).key?(:on_behalf_of)
      end
  end
end
