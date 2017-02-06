module Hyrax
  class Admin::AdminSetsController < ApplicationController
    include Hyrax::CollectionsControllerBehavior

    # added skip to allow flash notices. see https://github.com/projecthydra-labs/hyrax/issues/202
    skip_before_action :filter_docs_with_read_access!
    before_action :ensure_admin!
    load_and_authorize_resource

    layout 'admin'
    self.presenter_class = Hyrax::AdminSetPresenter
    self.form_class = Hyrax::Forms::AdminSetForm

    # Used for the show action
    self.single_item_search_builder_class = Hyrax::SingleAdminSetSearchBuilder

    # Used to get the members for the show action
    self.member_search_builder_class = Hyrax::AdminSetMemberSearchBuilder

    # Used to get a list of admin sets for the index action
    self.list_search_builder_class = Hyrax::AdminSetSearchBuilder

    # Used to create the admin set
    class_attribute :admin_set_create_service
    self.admin_set_create_service = AdminSetCreateService

    def show
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.toolbar.admin.menu'), hyrax.admin_path
      add_breadcrumb t(:'hyrax.admin.sidebar.admin_sets'), hyrax.admin_admin_sets_path
      add_breadcrumb 'View Set', request.path
      super
    end

    def index
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.toolbar.admin.menu'), hyrax.admin_path
      add_breadcrumb t(:'hyrax.admin.sidebar.admin_sets'), hyrax.admin_admin_sets_path
      @admin_sets = Hyrax::AdminSetService.new(self).search_results(:read)
    end

    def new
      setup_form
    end

    def edit
      setup_form
    end

    def update
      if @admin_set.update(admin_set_params)
        redirect_to hyrax.admin_admin_sets_path
      else
        setup_form
        render :edit
      end
    end

    def create
      if create_admin_set
        redirect_to hyrax.edit_admin_admin_set_path(@admin_set), notice: I18n.t('new_admin_set', scope: 'hyrax.admin.admin_sets.form.permission_update_notices', name: @admin_set.title.first)
      else
        setup_form
        render :new
      end
    end

    def destroy
      if @admin_set.destroy
        redirect_to hyrax.admin_admin_sets_path, notice: t(:'hyrax.admin.admin_sets.delete.notification')
      else
        redirect_to hyrax.admin_admin_set_path(@admin_set), alert: @admin_set.errors.full_messages.to_sentence
      end
    end

    # for the AdminSetService
    def repository
      repository_class.new(blacklight_config)
    end

    # Override the default prefixes so that we use the collection partals.
    def self.local_prefixes
      ["hyrax/admin/admin_sets", "hyrax/collections", 'catalog']
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
        admin_set_create_service.call(@admin_set, current_user)
      end

      def setup_form
        add_breadcrumb t(:'hyrax.controls.home'), root_path
        add_breadcrumb t(:'hyrax.toolbar.admin.menu'), hyrax.admin_path
        add_breadcrumb t(:'hyrax.admin.sidebar.admin_sets'), hyrax.admin_admin_sets_path
        add_breadcrumb action_breadcrumb, request.path
        @form = form_class.new(@admin_set)
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
  end
end
