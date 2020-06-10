# frozen_string_literal: true
module Hyrax
  module Breadcrumbs
    extend ActiveSupport::Concern

    def build_breadcrumbs
      if request.referer
        trail_from_referer
      else
        default_trail
        add_breadcrumb_for_controller if user_signed_in?
        add_breadcrumb_for_action
      end
    end

    def default_trail
      add_breadcrumb I18n.t('hyrax.controls.home'), hyrax.root_path
      add_breadcrumb I18n.t('hyrax.dashboard.title'), hyrax.dashboard_path if user_signed_in?
    end

    def trail_from_referer
      case request.referer
      when /catalog/
        add_breadcrumb I18n.t('hyrax.controls.home'), hyrax.root_path
        add_breadcrumb I18n.t('hyrax.bread_crumb.search_results'), request.referer
      else
        default_trail
        add_breadcrumb_for_controller if user_signed_in?
        add_breadcrumb_for_action
      end
    end

    # Override these in your controller
    def add_breadcrumb_for_controller; end

    # Override these in your controller
    def add_breadcrumb_for_action; end
  end
end
