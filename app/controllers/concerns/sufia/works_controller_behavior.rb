module Sufia
  module WorksControllerBehavior
    extend ActiveSupport::Concern
    include Sufia::Controller
    include CurationConcerns::CurationConcernController

    included do
      include Sufia::Breadcrumbs
      before_action :has_access?, except: :show
      before_action :build_breadcrumbs, only: [:edit, :show]
      self.curation_concern_type = GenericWork
      self.show_presenter = Sufia::WorkShowPresenter
      layout "sufia-one-column"
    end

    def new
      curation_concern.depositor = current_user.user_key
      super
    end

    def edit
      work = _curation_concern_type.find(params[:id])
      raise "Cannot edit a work that still is being processed" if work.processing?
      super
    end

    def actor
      @actor ||= CurationConcerns::CurationConcern::ActorStack.new(
        curation_concern,
        current_user,
        [CreateWithFilesActor,
         CurationConcerns::AddToCollectionActor,
         CurationConcerns::AssignRepresentativeActor,
         CurationConcerns::AttachFilesActor,
         CurationConcerns::ApplyOrderActor,
         CurationConcerns::InterpretVisibilityActor,
         CurationConcerns::CurationConcern.model_actor(curation_concern),
         CurationConcerns::AssignIdentifierActor])
    end

    # Override the default behavior from curation_concerns in order to add uploaded_files to the parameters received by the actor.
    def attributes_for_actor
      super.merge(params.slice(:uploaded_files))
    end

    def after_create_response
      respond_to do |wants|
        wants.html do
          flash[:notice] = "Your files are being processed by #{view_context.application_name} in " \
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

      # Called by CurationConcerns::FileSetsControllerBehavior#show
      def additional_response_formats(format)
        format.endnote { render text: presenter.solr_document.export_as_endnote }
      end
  end
end
