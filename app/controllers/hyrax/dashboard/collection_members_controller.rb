# frozen_string_literal: true
module Hyrax
  module Dashboard
    ## Shows a list of all collections to the admins
    class CollectionMembersController < Hyrax::My::CollectionsController
      before_action :filter_docs_with_read_access!

      include Hyrax::Collections::AcceptsBatches

      load_resource only: :update_members,
                    instance_name: :collection,
                    class: Hyrax.config.collection_model

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

      def update_members # rubocop:disable Metrics/MethodLength
        err_msg = validate
        after_update_error(err_msg) if err_msg.present?
        return if err_msg.present?

        @collection.try(:reindex_extent=, Hyrax::Adapters::NestingIndexAdapter::LIMITED_REINDEX)
        begin
          Hyrax::Collections::CollectionMemberService.add_members_by_ids(collection_id: collection_id,
                                                                         new_member_ids: batch_ids,
                                                                         user: current_user)
          after_update
        rescue Hyrax::SingleMembershipError => err
          messages = JSON.parse(err.message)
          if messages.size == batch_ids.size
            after_update_error(messages.uniq.join(', '))
          elsif messages.present?
            flash[:error] = messages.uniq.join(', ')
            after_update
          end
        end
      end

      private

      def validate
        return t('hyrax.dashboard.my.action.members_no_access') if
          batch_ids.blank?
        return t('hyrax.dashboard.my.action.collection_deny_add_members') unless
          current_ability.can?(:deposit, @collection)
        return t('hyrax.dashboard.my.action.add_to_collection_only') unless
          member_action == "add" # should never happen
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

      def batch_ids
        params[:batch_document_ids]
      end

      def member_action
        params[:collection][:members]
      end
    end
  end
end
