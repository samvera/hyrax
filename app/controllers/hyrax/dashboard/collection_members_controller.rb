module Hyrax
  module Dashboard
    ## Shows a list of all collections to the admins
    class CollectionMembersController < Hyrax::My::CollectionsController
      before_action :filter_docs_with_read_access!

      include Hyrax::Collections::AcceptsBatches

      def after_update
        respond_to do |format|
          format.html { redirect_to success_return_path, notice: t('hyrax.dashboard.my.action.collection_update_success') }
          format.json { render json: @collection, status: :updated, location: dashboard_collection_path(@collection) }
        end
      end

      def after_update_error(err_msg)
        respond_to do |format|
          format.html { redirect_to err_return_path, alert: err_msg }
          format.json { render json: @collection.errors, status: :unprocessable_entity }
        end
      end

      def update_members
        err_msg = validate
        after_update_error(err_msg) if err_msg.present?
        return if err_msg.present?

        collection.reindex_extent = Hyrax::Adapters::NestingIndexAdapter::LIMITED_REINDEX
        members = collection.add_member_objects batch_ids
        messages = members.collect { |member| member.errors.full_messages }.flatten
        if messages.size == members.size
          after_update_error(messages.uniq.join(', '))
        elsif messages.present?
          flash[:error] = messages.uniq.join(', ')
          after_update
        else
          after_update
        end
      end

      private

        def validate
          return t('hyrax.dashboard.my.action.members_no_access') if batch_ids.blank?
          return t('hyrax.dashboard.my.action.collection_deny_add_members') unless current_ability.can?(:deposit, collection)
          return t('hyrax.dashboard.my.action.add_to_collection_only') unless member_action == "add" # should never happen
        end

        def success_return_path
          dashboard_collection_path(collection_id)
        end

        def err_return_path
          dashboard_collections_path
        end

        def collection_id
          params[:id]
        end

        def collection
          @collection ||= Collection.find(collection_id)
        end

        def batch_ids
          params[:batch_document_ids]
        end

        def member_action
          params[:collection][:members]
        end
    end
  end
end
