# frozen_string_literal: true
module Hyrax
  module Collections
    module AcceptsBatches
      def batch
        @batch ||= batch_ids_from_params
      end

      def batch=(val)
        @batch = val
      end

      # Callback to be used in before_filter
      def check_for_empty_batch?
        batch.empty?
      end

      private

      def batch_ids_from_params
        if params['batch_document_ids'].blank?
          []
        elsif params['batch_document_ids'] == 'all'
          SearchService.new(session, current_user.user_key).last_search_documents.map(&:id)
        else
          params['batch_document_ids']
        end
      end

      def filter_docs_with_read_access!
        filter_docs_with_access!(:read)
      end

      def filter_docs_with_edit_access!
        filter_docs_with_access!(:edit)
      end

      def filter_docs_with_access!(access_type = :edit)
        no_permissions = []
        if batch.empty?
          flash[:notice] = 'Select something first'
        else
          batch.dup.each do |doc_id|
            unless can?(access_type, doc_id)
              batch.delete(doc_id)
              no_permissions << doc_id
            end
          end
          flash[:notice] = "You do not have permission to edit the documents: #{no_permissions.join(', ')}" unless no_permissions.empty?
        end
      end
    end
  end
end
