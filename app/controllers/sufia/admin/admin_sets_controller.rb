module Sufia
  class Admin::AdminSetsController < ApplicationController
    include CurationConcerns::CollectionsControllerBehavior

    before_action :ensure_admin!
    load_and_authorize_resource

    layout 'admin'
    self.presenter_class = Sufia::AdminSetPresenter
    self.form_class = Sufia::Forms::AdminSetForm

    # Used for the show action
    self.single_item_search_builder_class = Sufia::SingleAdminSetSearchBuilder

    # Used to get the members for the show action
    self.member_search_builder_class = Sufia::AdminSetMemberSearchBuilder

    # Used to get a list of admin sets for the index action
    self.list_search_builder_class = CurationConcerns::AdminSetSearchBuilder

    def show
      add_breadcrumb t(:'sufia.controls.home'), root_path
      add_breadcrumb t(:'sufia.toolbar.admin.menu'), sufia.admin_path
      add_breadcrumb t(:'sufia.admin.sidebar.admin_sets'), sufia.admin_admin_sets_path
      add_breadcrumb 'View Set', request.path
      super
    end

    def index
      add_breadcrumb t(:'sufia.controls.home'), root_path
      add_breadcrumb t(:'sufia.toolbar.admin.menu'), sufia.admin_path
      add_breadcrumb t(:'sufia.admin.sidebar.admin_sets'), sufia.admin_admin_sets_path
      @admin_sets = CurationConcerns::AdminSetService.new(self).search_results(:read)
    end

    def new
      setup_form
    end

    def edit
      setup_form
    end

    def update
      if @admin_set.update(admin_set_params)
        permission_template.update(permission_template_params)
        redirect_to sufia.admin_admin_sets_path
      else
        setup_form
        render :edit
      end
    end

    def create
      if create_admin_set
        permission_template_holder = permission_template
        permission_template_holder.attributes = permission_template_params
        permission_template_holder.save! # to create permission template on create
        redirect_to sufia.admin_admin_sets_path
      else
        setup_form
        render :new
      end
    end

    # for the AdminSetService
    def repository
      repository_class.new(blacklight_config)
    end

    # Override the default prefixes so that we use the collection partals.
    def self.local_prefixes
      ["sufia/admin/admin_sets", "collections", 'catalog']
    end

    private

      def ensure_admin!
        # Even though the user can view this admin set, they may not be able to view
        # it on the admin page.
        authorize! :read, :admin_dashboard
      end

      # Overriding the way that the search builder is initialized
      def list_search_builder
        list_search_builder_class.new(self, :read)
      end

      def create_admin_set
        AdminSetCreateService.new(@admin_set, current_user).create
      end

      def setup_form
        add_breadcrumb t(:'sufia.controls.home'), root_path
        add_breadcrumb t(:'sufia.toolbar.admin.menu'), sufia.admin_path
        add_breadcrumb t(:'sufia.admin.sidebar.admin_sets'), sufia.admin_admin_sets_path
        add_breadcrumb action_breadcrumb, request.path
        @form = form_class.new(@admin_set, permission_template)
      end

      # Find or create the permission_template object for this admin set
      def permission_template
        PermissionTemplate.find_or_initialize_by(admin_set_id: @admin_set.id)
      end

      def action_breadcrumb
        case action_name
        when 'edit', 'update'
          t(:'helpers.action.edit')
        else
          t(:'helpers.action.admin_set.new')
        end
      end

      def admin_set_params
        form_class.model_attributes(params[:admin_set])
      end

      def repository_class
        blacklight_config.repository_class
      end

      def permission_template_params
        { "workflow_name" => params[:admin_set][:workflow_name] }
      end
  end
end
