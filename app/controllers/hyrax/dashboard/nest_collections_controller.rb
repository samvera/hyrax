# frozen_string_literal: true
module Hyrax
  module Dashboard
    ##
    # @api public
    class NestCollectionsController < ApplicationController
      include Blacklight::Base

      class_attribute :form_class, :new_collection_form_class
      self.form_class = Hyrax::Forms::Dashboard::NestCollectionForm
      self.new_collection_form_class = Hyrax::Forms::CollectionForm

      # Add this collection as a subcollection within another existing collection
      def create_relationship_within
        authorize! :read, form_params[:child_id]

        if form.save
          notice = I18n.t('create_within', scope: 'hyrax.dashboard.nest_collections_form', child_title: form.child.title.first, parent_title: form.parent.title.first)
          redirect_to redirect_path(item: form.child), notice: notice
        else
          redirect_to redirect_path(item: form.child), flash: { error: form.errors.full_messages }
        end
      end

      # create and link a NEW subcollection under this collection, with this collection as parent
      def create_collection_under
        authorize! :deposit, form_params[:parent_id]

        if form.validate_add
          redirect_to new_dashboard_collection_path(collection_type_id: parent_type_id_for(form), parent_id: form.parent)
        else
          redirect_to redirect_path(item: form.parent), flash: { error: form.errors.full_messages }
        end
      end

      # link this collection as parent by adding existing collection as subcollection under this one
      def create_relationship_under
        authorize! :read, form_params[:parent_id]

        if form.save
          notice = I18n.t('create_under', scope: 'hyrax.dashboard.nest_collections_form', child_title: form.child.title.first, parent_title: form.parent.title.first)
          redirect_to redirect_path(item: form.parent), notice: notice
        else
          redirect_to redirect_path(item: form.parent), flash: { error: form.errors.full_messages }
        end
      end

      # remove a parent collection relationship from this collection
      def remove_relationship_above
        authorize! :edit, form_params[:parent_id]
        if form.remove
          notice = I18n.t('removed_relationship', scope: 'hyrax.dashboard.nest_collections_form', child_title: form.child.title.first, parent_title: form.parent.title.first)
          redirect_to redirect_path(item: form.child), notice: notice
        else
          redirect_to redirect_path(item: form.child), flash: { error: form.errors.full_messages }
        end
      end

      # remove a subcollection relationship from this collection
      def remove_relationship_under
        authorize! :edit, form_params[:parent_id]

        if form.remove
          notice = I18n.t('removed_relationship', scope: 'hyrax.dashboard.nest_collections_form', child_title: form.child.title.first, parent_title: form.parent.title.first)
          redirect_to redirect_path(item: form.parent), notice: notice
        else
          redirect_to redirect_path(item: form.parent), flash: { error: form.errors.full_messages }
        end
      end

      private

      ##
      # @deprecated
      def build_within_form
        authorize! :read, form_params[:child_id]
        form_class.new(context: self, **form_params.to_h.symbolize_keys)
      end
      deprecation_deprecate :build_within_form

      ##
      # @deprecated
      def build_under_form
        authorize! :read, form_params[:parent_id]
        form_class.new(context: self, **form_params.to_h.symbolize_keys)
      end
      deprecation_deprecate :build_under_form

      ##
      # @deprecated
      def build_create_collection_form
        authorize! :deposit, form_params[:parent_id]
        form_class.new(context: self, **form_params.to_h.symbolize_keys)
      end
      deprecation_deprecate :build_create_collection_form

      ##
      # @deprecated
      def build_remove_form
        authorize! :edit, form_params[:parent_id]
        form_class.new(context: self, **form_params.to_h.symbolize_keys)
      end
      deprecation_deprecate :build_create_collection_form

      ##
      # @api public
      # @since 3.2.0
      def form
        @form ||=
          form_class.new(context: self, **form_params.to_h.symbolize_keys)
      end

      ##
      # @api public
      # @since 3.2.0
      def form_params
        params.slice(:child_id, :parent_id).permit!
      end

      ##
      # @api public
      #
      # determine appropriate redirect location depending on specified source
      def redirect_path(item:)
        return my_collections_path if params[:source] == 'my'
        dashboard_collection_path(item)
      end

      ##
      # @api private
      def parent_type_id_for(form)
        URI::GID.parse(form.parent.collection_type_gid).model_id
      end
    end
  end
end
