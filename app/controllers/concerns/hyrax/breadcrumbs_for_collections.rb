module Hyrax
  module BreadcrumbsForCollections
    extend ActiveSupport::Concern
    include Hyrax::Breadcrumbs

    included do
      before_action :build_breadcrumbs, only: [:edit, :show]
    end

    def add_breadcrumb_for_controller
      add_breadcrumb I18n.t('hyrax.dashboard.my.collections'), hyrax.my_collections_path
    end

    def add_breadcrumb_for_action
      case action_name
      when 'edit'.freeze
        add_breadcrumb I18n.t("hyrax.collection.browse_view"), collection_path(params["id"]), mark_active_action
      when 'show'.freeze
        add_breadcrumb presenter.to_s, polymorphic_path(presenter), mark_active_action
      end
    end

    def mark_active_action
      { "aria-current" => "page" }
    end
  end
end
