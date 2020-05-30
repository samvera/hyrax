# frozen_string_literal: true

module Hyrax
  module Specs
    class SpyListener
      attr_reader :file_set_attached, :file_set_url_imported, :object_deleted,
                  :object_deposited, :object_failed_deposit, :object_acl_updated,
                  :object_metadata_updated

      def on_object_deleted(event)
        @object_deleted = event
      end

      def on_object_deposited(event)
        @object_deposited = event
      end

      def on_object_failed_deposit(event)
        @object_failed_deposit = event
      end

      def on_object_acl_updated(event)
        @object_acl_updated = event
      end

      def on_object_metadata_updated(event)
        @object_metadata_updated = event
      end

      def on_file_set_attached(event)
        @file_set_attached = event
      end

      def on_file_set_url_imported(event)
        @file_set_url_imported = event
      end
    end
  end
end
