module Hyrax
  class Admin::CollectionTypesController < ApplicationController
    before_action do
      authorize! :manage, :collection_types
    end

    layout 'dashboard'
    class_attribute :form_class
    self.form_class = Hyrax::Forms::Admin::CollectionTypeForm
    load_resource class: Hyrax::CollectionType, except: [:index, :show, :create], instance_name: :collection_type

    def index
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
      add_breadcrumb t(:'hyrax.admin.sidebar.configuration'), '#'
      add_breadcrumb t(:'hyrax.admin.sidebar.collection_types'), request.path

      # TODO: How do we know if a collection_type has existing collections?
      # Will that be a property on @collection_types here?
      @collection_types = Hyrax::CollectionType.all
    end

    def new
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
      add_breadcrumb t(:'hyrax.admin.sidebar.configuration'), '#'
      add_breadcrumb t(:'hyrax.admin.collection_types.index.breadcrumb'), hyrax.admin_collection_types_path
      add_breadcrumb t(:'hyrax.admin.collection_types.new.header'), hyrax.new_admin_collection_type_path
      @form = form_class.new(collection_type: @collection_type)
    end

    def create; end

    def edit
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
      add_breadcrumb t(:'hyrax.admin.sidebar.configuration'), '#'
      add_breadcrumb t(:'hyrax.admin.collection_types.index.breadcrumb'), hyrax.admin_collection_types_path
      add_breadcrumb t(:'hyrax.admin.collection_types.edit.header'), hyrax.edit_admin_collection_type_path
      @form = form_class.new(collection_type: @collection_type)
    end

    def update; end

    def destroy; end
  end
end
