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
      # TODO: move this to curation_concerns
      @form = form_class.new(curation_concern, current_ability)
      curation_concern.depositor = (current_user.user_key)
      super
    end

    protected

      def show_presenter
        Sufia::WorkShowPresenter
      end

      # Called by CurationConcerns::FileSetsControllerBehavior#show
      def additional_response_formats(format)
        # TODO: This duplicates the same process in CurationConcerns::CurationConcernController.show
        # for assigning a presenter. It could be extracted into a common method.
        format.endnote do
          _, document_list = search_results(params, CatalogController.search_params_logic + [:find_one])
          curation_concern = document_list.first
          raise CanCan::AccessDenied.new(nil, :show) unless curation_concern
          presenter = show_presenter.new(curation_concern, current_ability)
          render text: presenter.solr_document.export_as_endnote
        end
      end
  end
end
