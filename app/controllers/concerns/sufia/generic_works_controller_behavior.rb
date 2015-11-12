module Sufia
  module GenericWorksControllerBehavior
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
      # TODO: move this to curation_concerns
      @form = form_class.new(curation_concern, current_ability)
      super
    end

    protected

      def show_presenter
        Sufia::GenericWorkPresenter
      end
  end
end
