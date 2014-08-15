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
      if user_signed_in?
        add_breadcrumb I18n.t('sufia.dashboard.title'), sufia.dashboard_index_path
      end
    end

    def trail_from_referer
      case request.referer
      when /catalog/
        add_breadcrumb I18n.t('sufia.bread_crumb.search_results'), request.referer
      when /dashboard/
        default_trail
        add_breadcrumb_for_controller    
      else
        default_trail
      end
    end

    def add_breadcrumb_for_controller
      case controller_name
      when /files|batch/
        add_breadcrumb I18n.t('sufia.dashboard.my.files'), sufia.dashboard_files_path
      when /collections/
        add_breadcrumb I18n.t('sufia.dashboard.my.collections'), sufia.dashboard_collections_path
      end
    end

  end
end
