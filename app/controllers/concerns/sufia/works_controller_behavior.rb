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
      curation_concern.depositor = (current_user.user_key)
      super
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
