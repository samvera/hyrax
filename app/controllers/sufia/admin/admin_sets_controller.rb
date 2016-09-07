module Sufia
  class Admin::AdminSetsController < ApplicationController
    load_and_authorize_resource
    layout 'admin'

    def index
      authorize! :manage, AdminSet
      add_breadcrumb t(:'sufia.controls.home'), root_path
      add_breadcrumb t(:'sufia.toolbar.admin.menu'), sufia.admin_path
      add_breadcrumb t(:'sufia.admin.sidebar.admin_sets'), sufia.admin_admin_sets_path
      @admin_sets = CurationConcerns::AdminSetService.new(self).search_results(:read)
    end

    def new
      setup_create_form
    end

    def create
      if create_admin_set
        redirect_to sufia.admin_admin_sets_path
      else
        setup_create_form
        render :new
      end
    end

    # for the AdminSetService
    def repository
      repository_class.new(blacklight_config)
    end

    private

      def create_admin_set
        AdminSetService.new(@admin_set, current_user).create
      end

      def setup_create_form
        add_breadcrumb  'Home', root_path
        add_breadcrumb  'Repository Dashboard', sufia.admin_path
        add_breadcrumb  'Administrative Sets', sufia.admin_admin_sets_path
        add_breadcrumb  'New', sufia.new_admin_admin_set_path
        @form = form_class.new(@admin_set)
      end

      def admin_set_params
        form_class.model_attributes(params[:admin_set])
      end

      def form_class
        Forms::AdminSetForm
      end

      def repository_class
        blacklight_config.repository_class
      end
  end
end
