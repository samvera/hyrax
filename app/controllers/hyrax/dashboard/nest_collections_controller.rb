module Hyrax
  module Dashboard
    class NestCollectionsController < ApplicationController
      include Blacklight::Base
      class_attribute :form_class, :new_collection_form_class
      self.form_class = Hyrax::Forms::Dashboard::NestCollectionForm
      self.new_collection_form_class = Hyrax::Forms::CollectionForm

      # Add this collection within another collection (this collection as child)
      # def new_within
      #   @form = build_within_form
      # end

      def create_within
        @form = build_within_form
        if @form.save
          notice = I18n.t('create_within', scope: 'hyrax.dashboard.nest_collections_form', child_title: @form.child.title.first, parent_title: @form.parent.title.first)
          redirect_to redirect_path(item: @form.child), notice: notice
        else
          flash[:error] = @form.errors.full_messages
          redirect_to redirect_path(item: @form.child)
        end
      end

      # create and link new subcollection under this collection, (this collection as parent)
      def new_under
        @form = build_new_under_form
        if @form.validate_add
          redirect_to new_dashboard_collection_path(collection_type_id: @form.parent.collection_type.id, parent_id: @form.parent)
        else
          flash[:error] = @form.errors.full_messages
          redirect_to redirect_path(item: @form.parent)
        end
      end

      def create_under
        @form = build_under_form
        if @form.save
          notice = I18n.t('create_under', scope: 'hyrax.dashboard.nest_collections_form', child_title: @form.child.title.first, parent_title: @form.parent.title.first)
          redirect_to redirect_path(item: @form.parent), notice: notice
        else
          flash[:error] = @form.errors.full_messages
          redirect_to redirect_path(item: @form.parent)
        end
      end

      private

        def build_within_form
          child = Collection.find(params.fetch(:child_id))
          authorize! :edit, child
          parent = params.key?(:parent_id) ? Collection.find(params[:parent_id]) : nil
          form_class.new(child: child, parent: parent, context: self)
        end

        def build_under_form
          parent = Collection.find(params.fetch(:parent_id))
          authorize! :edit, parent
          child = params.key?(:child_id) ? Collection.find(params[:child_id]) : nil
          form_class.new(child: child, parent: parent, context: self)
        end

        def build_new_under_form
          parent = Collection.find(params.fetch(:parent_id))
          authorize! :edit, parent
          form_class.new(child: nil, parent: parent, context: self)
        end

        # determine appropriate redirect location depending on specified source
        def redirect_path(item:)
          source = params[:source] || 'none'
          path = case source
          when "my"
            my_collections_path
          when "show"
            dashboard_collection_path(item)
          when "edit"
            edit_dashboard_collection_path(item, anchor: 'relationships')
          else
            dashboard_collection_path(item)
          end
        end
    end
  end
end
