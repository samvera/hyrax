module Hyrax
  class Admin::AdminSetsController < ApplicationController
    include Hyrax::CollectionsControllerBehavior

    before_action :authenticate_user!
    before_action :ensure_manager!, except: [:show]
    load_and_authorize_resource
    before_action :ensure_viewer!, only: [:show]

    # Catch permission errors
    rescue_from Hydra::AccessDenied, CanCan::AccessDenied, with: :deny_adminset_access

    with_themed_layout 'dashboard'
    self.presenter_class = Hyrax::AdminSetPresenter
    self.form_class = Hyrax::Forms::AdminSetForm

    # Used for the show action
    self.single_item_search_builder_class = Hyrax::SingleAdminSetSearchBuilder

    # The search builder to find the admin set's members
    self.membership_service_class = Hyrax::AdminSetMemberService

    # Used to create the admin set
    class_attribute :admin_set_create_service
    self.admin_set_create_service = AdminSetCreateService

    def deny_adminset_access(exception)
      if current_user && current_user.persisted?
        redirect_to root_url, alert: exception.message
      else
        session['user_return_to'] = request.url
        redirect_to main_app.new_user_session_url, alert: exception.message
      end
    end

    def show
      add_breadcrumb I18n.t('hyrax.controls.home'), hyrax.root_path
      add_breadcrumb t(:'hyrax.dashboard.title'), hyrax.dashboard_path
      add_breadcrumb t(:'hyrax.dashboard.my.collections'), hyrax.my_collections_path
      add_breadcrumb @admin_set.title.first
      super
    end

    def index
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
      add_breadcrumb t(:'hyrax.admin.sidebar.admin_sets'), hyrax.admin_admin_sets_path
      @admin_sets = Hyrax::AdminSetService.new(self).search_results(:edit)
    end

    def new
      setup_form
    end

    def edit
      setup_form
    end

    # Renders a JSON response with a list of files in this admin set.
    # This is used by the edit form to populate the thumbnail_id dropdown
    def files
      result = form.select_files.map { |label, id| { id: id, text: label } }
      render json: result
    end

    def update
      if @admin_set.update(admin_set_params)
        redirect_to update_referer, notice: I18n.t('updated_admin_set', scope: 'hyrax.admin.admin_sets.form.permission_update_notices', name: @admin_set.title.first)
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
        after_delete_success
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

      def update_referer
        hyrax.edit_admin_admin_set_path(@admin_set) + (params[:referer_anchor] || '')
      end

      def ensure_manager!
        # TODO: Review for possible removal.  Doesn't appear to apply anymore.
        # Even though the user can view this admin set, they may not be able to view
        # it on the admin page.
        authorize! :manage_any, AdminSet
      end

      def ensure_viewer!
        # Even though the user can view this admin set, they may not be able to view
        # it on the admin page if access is granted as a public or registered user only.
        authorize! :view_admin_show, @admin_set
      end

      def create_admin_set
        admin_set_create_service.call(admin_set: @admin_set, creating_user: current_user)
      end

      def setup_form
        add_breadcrumb t(:'hyrax.controls.home'), root_path
        add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
        add_breadcrumb t(:'hyrax.dashboard.my.collections'), hyrax.my_collections_path
        add_breadcrumb action_breadcrumb, request.path
        form
      end

      # initialize the form object
      def form
        @form ||= form_class.new(@admin_set, current_ability, repository)
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

      def after_delete_success
        if request.referer.include? "my/collections"
          redirect_to hyrax.my_collections_path, notice: t(:'hyrax.admin.admin_sets.delete.notification')
        elsif request.referer.include? "collections"
          redirect_to hyrax.dashboard_collections_path, notice: t(:'hyrax.admin.admin_sets.delete.notification')
        else
          redirect_to hyrax.my_collections_path, notice: t(:'hyrax.admin.admin_sets.delete.notification')
        end
      end
  end
end
