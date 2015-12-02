module Sufia
  module Breadcrumbs
    extend ActiveSupport::Concern

    def build_breadcrumbs
      if request.referer
        trail_from_referer
      else
        default_trail
      end
    end

    def default_trail
      add_breadcrumb I18n.t('sufia.dashboard.title'), sufia.dashboard_index_path if user_signed_in?
    end

    def trail_from_referer
      case request.referer
      when /catalog/
        add_breadcrumb I18n.t('sufia.bread_crumb.search_results'), request.referer
      else
        default_trail
        add_breadcrumb_for_controller
        add_breadcrumb_for_action
      end
    end

    def add_breadcrumb_for_controller
      case controller_name
      when 'file_sets'.freeze, 'my/files'.freeze, 'batch_edits'.freeze
        add_breadcrumb I18n.t('sufia.dashboard.my.files'), sufia.dashboard_files_path
      when 'stats'.freeze
        add_breadcrumb I18n.t('sufia.dashboard.my.files'), sufia.dashboard_files_path
      when 'my/collections'.freeze
        add_breadcrumb I18n.t('sufia.dashboard.my.collections'), sufia.dashboard_collections_path
      end
    end

    def add_breadcrumb_for_action
      case controller_name
      when 'file_sets'.freeze
        add_breadcrumb I18n.t("sufia.file_set.browse_view"), Rails.application.routes.url_helpers.curation_concerns_file_set_path(params["id"]) if action_name.eql? 'edit'
      when 'stats'.freeze
        add_breadcrumb I18n.t("sufia.file_set.browse_view"), Rails.application.routes.url_helpers.curation_concerns_file_set_path(params["id"]) if action_name.eql? 'file'
        add_breadcrumb I18n.t("sufia.work.browse_view"), Rails.application.routes.url_helpers.curation_concerns_file_set_path(params["id"]) if action_name.eql? 'work'
      end
    end
  end
end
