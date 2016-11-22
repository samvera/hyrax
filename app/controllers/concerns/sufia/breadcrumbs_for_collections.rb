module Sufia
  module BreadcrumbsForCollections
    extend ActiveSupport::Concern
    include Sufia::Breadcrumbs

    included do
      before_action :build_breadcrumbs, only: [:edit, :show]
    end

    def add_breadcrumb_for_controller
      add_breadcrumb I18n.t('sufia.dashboard.my.collections'), sufia.dashboard_collections_path
    end

    def add_breadcrumb_for_action
      case action_name
      when 'edit'.freeze
        add_breadcrumb I18n.t("sufia.collection.browse_view"), main_app.collection_path(params["id"])
      when 'show'.freeze
        add_breadcrumb presenter.to_s, main_app.polymorphic_path(presenter)
      end
    end
  end
end
