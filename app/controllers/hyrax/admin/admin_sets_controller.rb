module Hyrax
  # rubocop:disable Metrics/ClassLength
  class Admin::AdminSetsController < ApplicationController
    include Hyrax::CollectionsControllerBehavior
    include Hyrax::ResourceController

    # added skip to allow flash notices. see https://github.com/samvera/hyrax/issues/202
    skip_before_action :filter_docs_with_read_access!
    before_action :ensure_manager!

    with_themed_layout 'dashboard'
    self.resource_class = AdminSet
    self.presenter_class = Hyrax::AdminSetPresenter
    self.change_set_class = Hyrax::AdminSetChangeSet
    self.change_set_persister = Hyrax::AdminSetChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie.config.storage_adapter
    )

    # Used for the show action
    self.single_item_search_builder_class = Hyrax::SingleAdminSetSearchBuilder

    # Used to get the members for the show action
    self.member_search_builder_class = Hyrax::AdminAdminSetMemberSearchBuilder

    # Used to create the admin set
    class_attribute :admin_set_create_service
    self.admin_set_create_service = AdminSetCreateService

    def show
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
      add_breadcrumb t(:'hyrax.admin.sidebar.admin_sets'), hyrax.admin_admin_sets_path
      add_breadcrumb t(:'hyrax.admin.admin_sets.show.breadcrumb'), request.path
      super
    end

    def index
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
      add_breadcrumb t(:'hyrax.admin.sidebar.admin_sets'), hyrax.admin_admin_sets_path
      @admin_sets = Hyrax::AdminSetService.new(self).search_results(:edit)
    end

    def new
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
      add_breadcrumb t(:'hyrax.admin.sidebar.admin_sets'), hyrax.admin_admin_sets_path
      add_breadcrumb action_breadcrumb, request.path
      super
    end

    def edit
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
      add_breadcrumb t(:'hyrax.admin.sidebar.admin_sets'), hyrax.admin_admin_sets_path
      add_breadcrumb action_breadcrumb, request.path
      super
    end

    # Renders a JSON response with a list of files in this admin set.
    # This is used by the edit form to populate the thumbnail_id dropdown
    def files
      @change_set = build_change_set(find_resource(params[:id]))
      authorize! :files, @change_set.resource
      result = @change_set.select_files.map do |label, id|
        { id: id, text: label }
      end
      render json: result
    end

    def create
      @change_set = build_change_set(resource_class.new)
      authorize! :create, @change_set.resource
      @resource = create_admin_set
      if @resource
        after_create_success(@resource, @change_set)
      else
        after_create_error(@resource, @change_set)
      end
    end

    def destroy
      @change_set = build_change_set(find_resource(params[:id]))
      authorize! :destroy, @change_set.resource
      result = nil
      change_set_persister.buffer_into_index do |persist|
        # Returns truthy (an array) if this update worked, otherwise false
        result = persist.delete(change_set: @change_set)
      end
      if result
        redirect_to hyrax.admin_admin_sets_path, notice: t(:'hyrax.admin.admin_sets.delete.notification')
      else
        redirect_to hyrax.admin_admin_set_path(@change_set.resource), alert: @change_set.errors.full_messages.to_sentence
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

      def after_update_success(resource, _change_set)
        redirect_to hyrax.edit_admin_admin_set_path(resource),
                    notice: I18n.t('updated_admin_set',
                                   scope: 'hyrax.admin.admin_sets.form.permission_update_notices',
                                   name: resource.title.first)
      end

      def after_update_error(_resource, _change_set)
        add_breadcrumb t(:'hyrax.controls.home'), root_path
        add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
        add_breadcrumb t(:'hyrax.admin.sidebar.admin_sets'), hyrax.admin_admin_sets_path
        add_breadcrumb action_breadcrumb, request.path
        render :edit
      end

      def after_create_success(resource, _change_set)
        redirect_to hyrax.edit_admin_admin_set_path(resource),
                    notice: I18n.t('new_admin_set',
                                   scope: 'hyrax.admin.admin_sets.form.permission_update_notices',
                                   name: resource.title.first)
      end

      def after_create_error(_resource, _change_set)
        add_breadcrumb t(:'hyrax.controls.home'), root_path
        add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
        add_breadcrumb t(:'hyrax.admin.sidebar.admin_sets'), hyrax.admin_admin_sets_path
        add_breadcrumb action_breadcrumb, request.path
        render :new
      end

      def ensure_manager!
        # Even though the user can view this admin set, they may not be able to view
        # it on the admin page.
        authorize! :manage_any, AdminSet
      end

      def create_admin_set
        # TODO: pass the change_set here?
        admin_set_create_service.call(admin_set: @change_set.resource, creating_user: current_user)
      end

      # Overrides the parent implementation so that the returned search builder
      #  searches for edit access
      # Instantiates the search builder that builds a query for a single item
      # this is useful in the show view.
      def single_item_search_builder
        single_item_search_builder_class.new(self, :edit).with(params.except(:q, :page))
      end

      def action_breadcrumb
        case action_name
        when 'edit', 'update'
          t(:'helpers.action.edit')
        else
          t(:'helpers.action.admin_set.new')
        end
      end

      def repository_class
        blacklight_config.repository_class
      end
    # rubocop:enable Metrics/ClassLength
  end
end
