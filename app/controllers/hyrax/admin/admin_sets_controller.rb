# frozen_string_literal: true
module Hyrax
  class Admin::AdminSetsController < ApplicationController
    include Hyrax::CollectionsControllerBehavior

    before_action :authenticate_user!
    load_and_authorize_resource instance_name: :admin_set,
                                class: Hyrax.config.admin_set_model

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
      if current_user&.persisted?
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
      # admin sets are listed with collections
      redirect_to hyrax.my_collections_url
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
      case @admin_set
      when Valkyrie::Resource
        valkyrie_update
      else
        active_fedora_update
      end
    end

    def after_create
      Hyrax::SolrService.commit
      redirect_to hyrax.edit_admin_admin_set_path(admin_set_id),
                  notice: I18n.t('new_admin_set',
                                 scope: 'hyrax.admin.admin_sets.form.permission_update_notices',
                                 name: @admin_set.title.first)
    end

    def after_create_error(err_msg: "")
      msg = "Failed to create admin set: #{err_msg}"
      setup_form
      flash[:error] = msg
      Hyrax.logger.error(msg)
      render :new
    end

    def create
      case @admin_set
      when Valkyrie::Resource
        valkyrie_create
      else
        active_fedora_create
      end
    end

    def destroy
      case @admin_set
      when Valkyrie::Resource
        transactions['admin_set_resource.destroy'].call(@admin_set).value_or do |failure|
          redirect_to hyrax.admin_admin_set_path(admin_set_id), alert: failure.first
        end
        after_delete_success
      else
        if @admin_set.destroy
          after_delete_success
        else
          redirect_to hyrax.admin_admin_set_path(admin_set_id), alert: @admin_set.errors.full_messages.to_sentence
        end
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

    def valkyrie_update
      @admin_set = form.validate(admin_set_params) && transactions['admin_set_resource.update'].call(form).value_or do |_failure|
        setup_form # probably should do some real error handling here
        render :edit
      end
      redirect_to update_referer, notice: I18n.t('updated_admin_set', scope: 'hyrax.admin.admin_sets.form.permission_update_notices', name: @admin_set.title.first)
    end

    def active_fedora_update
      if @admin_set.update(admin_set_params)
        redirect_to update_referer, notice: I18n.t('updated_admin_set', scope: 'hyrax.admin.admin_sets.form.permission_update_notices', name: @admin_set.title.first)
      else
        setup_form
        render :edit
      end
    end

    def update_referer
      hyrax.edit_admin_admin_set_path(admin_set_id) + (params[:referer_anchor] || '')
    end

    def valkyrie_create
      form.validate(admin_set_params) &&
        @admin_set = transactions['change_set.create_admin_set']
                     .with_step_args(
                       'change_set.set_user_as_creator' => { user: current_user },
                       'admin_set_resource.apply_collection_type_permissions' => { user: current_user }
                     )
                     .call(form).value_or do |_failure|
                       setup_form # probably should do some real error handling here
                       render :edit
                     end
      @admin_set = admin_set_create_service.call!(admin_set: @admin_set, creating_user: current_user)
      after_create
    rescue RuntimeError => err
      after_create_error(err_msg: err.message)
    end

    def active_fedora_create
      updated_admin_set = admin_set_create_service.call!(admin_set: admin_set_resource, creating_user: current_user)
      @admin_set = Wings::ActiveFedoraConverter.convert(resource: updated_admin_set)
      after_create
    rescue RuntimeError => err
      after_create_error(err_msg: err.message)
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
      @form ||=
        case @admin_set
        when Valkyrie::Resource
          Hyrax::Forms::ResourceForm.for(@admin_set)
        else
          form_class.new(@admin_set, current_ability, repository)
        end
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
      if Hyrax.config.admin_set_class < ActiveFedora::Base
        form_class.model_attributes(params[:admin_set])
      else
        params.permit(admin_set: {})[:admin_set]
      end
    end

    def repository_class
      blacklight_config.repository_class
    end

    def after_delete_success
      if request.referer&.include? "my/collections"
        redirect_to hyrax.my_collections_path, notice: t(:'hyrax.admin.admin_sets.delete.notification')
      elsif request.referer&.include? "collections"
        redirect_to hyrax.dashboard_collections_path, notice: t(:'hyrax.admin.admin_sets.delete.notification')
      else
        redirect_to hyrax.my_collections_path, notice: t(:'hyrax.admin.admin_sets.delete.notification')
      end
    end

    def admin_set_id
      @admin_set&.id&.to_s
    end

    def admin_set_resource
      case @admin_set
      when Valkyrie::Resource
        @admin_set
      else
        @admin_set.valkyrie_resource
      end
    end
  end
end
