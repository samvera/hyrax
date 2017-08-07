module Hyrax
  class Admin::CollectionTypesController < ApplicationController
    before_action do
      authorize! :manage, :collection_types
    end

    layout 'dashboard'
    class_attribute :form_class
    self.form_class = Hyrax::Forms::Admin::CollectionTypeForm

    def index; end

    def new
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
      add_breadcrumb t(:'hyrax.admin.sidebar.configuration'), '#'
      add_breadcrumb t(:'hyrax.admin.collection_types.index.breadcrumb'), hyrax.admin_collection_types_path
      add_breadcrumb t(:'hyrax.admin.collection_types.new.header'), hyrax.new_admin_collection_type_path
      @form = form_class.new
    end

    def create; end

    def edit
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
      add_breadcrumb t(:'hyrax.admin.sidebar.configuration'), '#'
      add_breadcrumb t(:'hyrax.admin.collection_types.index.breadcrumb'), hyrax.admin_collection_types_path
      add_breadcrumb t(:'hyrax.admin.collection_types.edit.header'), hyrax.edit_admin_collection_type_path
      @form = form_class.new
    end

    def update; end

    def destroy; end
  end
end
