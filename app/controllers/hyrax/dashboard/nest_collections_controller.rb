module Hyrax
  module Dashboard
    class NestCollectionsController < ApplicationController
      include Blacklight::Base
      class_attribute :form_class
      self.form_class = Hyrax::Forms::Dashboard::NestCollectionForm

      def new_within
        @form = build_within_form
      end

      def create_within
        @form = build_within_form
        if @form.save
          notice = I18n.t('create_within', scope: 'hyrax.dashboard.nest_collections_form', child_title: @form.child.title, parent_title: @form.parent.title)
          redirect_to dashboard_collection_path(@form.child), notice: notice
        else
          render 'new_within'
        end
      end

      def process_nesting
        notice = "No mapping took place"
        unless params[:parent_id] == "none"
          parent_coll = Collection.find params[:parent_id]
          child_coll = Collection.find params[:child_id]

          child_coll.member_of_collections << parent_coll
          child_coll.save!

          notice = "Collections were mapped!"
        end

        if params[:source] == "my"
          redirect_to my_collections_path, notice: notice
        else
          redirect_to dashboard_collections_path, notice: notice
        end
      end

      private

        def build_within_form
          child = Collection.find(params.fetch(:child_id))
          authorize! :edit, child
          parent = params.key?(:parent_id) ? Collection.find(params[:parent_id]) : nil
          form_class.new(child: child, parent: parent, context: self)
        end
    end
  end
end
