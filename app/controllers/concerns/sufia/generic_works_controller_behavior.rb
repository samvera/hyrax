module Sufia
  module GenericWorksControllerBehavior
    extend ActiveSupport::Concern
    include Sufia::Controller

    include CurationConcerns::CurationConcernController

    included do
      include Sufia::Breadcrumbs

      before_action :has_access?, except: :show
      before_action :build_breadcrumbs, only: [:edit, :show]
      load_and_authorize_resource except: [:index, :audit], class: GenericWork

      set_curation_concern_type GenericWork
      layout "sufia-one-column"
    end

    def new
      super
      form
    end

    def edit
      super
      form
    end

    def show
      presenter
    end

    def create
      @generic_work.save!
      after_create
    end

    def update
      # do something
    end

    protected

      def after_create
        respond_to do |format|
          format.html { redirect_to sufia.generic_work_path(@generic_work), notice: 'GenericWork was successfully created.' }
          format.json { render json: @generic_work, status: :created, location: @generic_work }
        end
      end

      def after_create_error
      end

      def generic_work_params
        form_class.model_attributes(
          params.require(:generic_work).permit(:title, :description, :members, :on_behalf_of, part_of: [],
                                                                                              contributor: [], creator: [], publisher: [], date_created: [], subject: [],
                                                                                              language: [], rights: [], resource_type: [], identifier: [], based_near: [],
                                                                                              tag: [], related_url: [])
        )
      end

      def presenter
        @presenter ||= presenter_class.new(@generic_work)
      end

      def presenter_class
        Sufia::GenericWorkPresenter
      end

      def form
        @form ||= form_class.new(@generic_work)
      end

      def form_class
        CurationConcerns::Forms::GenericWorkEditForm
      end
  end
end
