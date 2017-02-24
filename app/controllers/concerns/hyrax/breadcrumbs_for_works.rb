module Hyrax
  module BreadcrumbsForWorks
    extend ActiveSupport::Concern
    include Hyrax::Breadcrumbs

    module ClassMethods
      # We don't want the breadcrumb action to occur until after the concern has
      # been loaded and authorized
      def curation_concern_type=(curation_concern_type)
        super
        before_action :build_breadcrumbs, only: [:edit, :show]
        before_action :save_permissions, only: :update
      end
    end

    def add_breadcrumb_for_controller
      add_breadcrumb I18n.t('hyrax.dashboard.my.works'), hyrax.my_works_path
    end

    def add_breadcrumb_for_action
      case action_name
      when 'edit'.freeze
        add_breadcrumb curation_concern.to_s, main_app.polymorphic_path(curation_concern)
        add_breadcrumb t('hyrax.works.edit.breadcrumb'), request.path
      when 'show'.freeze
        add_breadcrumb presenter.to_s, main_app.polymorphic_path(presenter)
      end
    end
  end
end
