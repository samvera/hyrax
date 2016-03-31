module Sufia
  module UploadSetsControllerBehavior
    extend ActiveSupport::Concern
    include Hydra::Controller::ControllerBehavior
    include GlobalID::Identification

    included do
      layout "sufia-one-column"

      before_action :has_access?
      class_attribute :edit_form_class
      self.edit_form_class = Sufia::UploadSetForm
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

      def redirect_after_update
        if uploading_on_behalf_of? @upload_set
          redirect_to sufia.dashboard_shares_path
        else
          redirect_to sufia.dashboard_works_path
        end
      end

      def edit_form
        edit_form_class.new(@upload_set, current_ability)
      end

      def create_update_job
        UploadSetUpdateJob.perform_later(current_user,
                                         @upload_set,
                                         params[:title],
                                         edit_form_class.model_attributes(params[:upload_set]),
                                         params[:visibility])
      end

      def uploading_on_behalf_of?(upload_set)
        return false if upload_set.works.empty?

        work = upload_set.works.first
        return false if work.nil? || work.on_behalf_of.blank?
        current_user.user_key != work.on_behalf_of
      end
  end
end
