module Sufia
  module WorksControllerBehavior
    extend ActiveSupport::Concern
    include Sufia::Controller
    include CurationConcerns::CurationConcernController

    included do
      include Sufia::Breadcrumbs
      before_action :has_access?, except: :show
      before_action :build_breadcrumbs, only: [:edit, :show]
      set_curation_concern_type GenericWork
      layout "sufia-one-column"
    end

    def new
      curation_concern.depositor = current_user.user_key
      super
    end

    def edit
      work = GenericWork.find(params[:id])
      raise "Cannot edit a work that still is being processed" if work.processing?
      super
    end

    def actor
      @actor ||= begin
                   inner_actor = CurationConcerns::CurationConcern.actor(curation_concern, current_user, attributes_for_actor)
                   Sufia::CreateWithFilesActor.new(inner_actor, params[:uploaded_files])
                 end
    end

    def after_create_response
      respond_to do |wants|
        wants.html do
          flash[:notice] = "Your files are being processed by #{t('curation_concerns.product_name')} in " \
            "the background. The metadata and access controls you specified are being applied. " \
            "Files will be marked <span class=\"label label-danger\" title=\"Private\">Private</span> " \
            "until this process is complete (shouldn't take too long, hang in there!). You may need " \
            "to refresh your dashboard to see these updates."
          redirect_to [main_app, curation_concern]
        end
        wants.json { render :show, status: :created, location: polymorphic_path([main_app, curation_concern]) }
      end
    end

    protected

      def show_presenter
        Sufia::WorkShowPresenter
      end

      # Called by CurationConcerns::FileSetsControllerBehavior#show
      def additional_response_formats(format)
        format.endnote { render text: presenter.solr_document.export_as_endnote }
      end
  end
end
