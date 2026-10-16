# frozen_string_literal: true

module Hyrax
  # Moves original files from the disk storage adapter to the S3 repository adapter
  # (see documentation/migrating-files-to-s3.md).
  module S3Migration
    class << self
      # Hosts that partition one repository into several (e.g. multitenant apps) can set a callable
      # returning a label for the current partition; manifest entries are then kept per label, so
      # the quarantine and rollback tasks only see the current partition's files.
      attr_writer :scope_provider

      def scope_provider
        @scope_provider ||= -> {}
      end

      def scope
        scope_provider.call.presence
      end

      # The Valkyrie file set class this app is configured with (Hyrax.config.file_set_model).
      def file_set_class
        Hyrax.config.valkyrie_file_set_class
      end
    end
  end
end
