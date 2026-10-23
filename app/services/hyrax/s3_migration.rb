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

      # Yields every file set stored in the repository, once. Lists each non-Wings query service directly,
      # once per name Hyrax registers for file sets (Hyrax::ModelRegistry.file_set_classes, which includes
      # Hyrax.config.file_set_model). The composite query service converts the model it is given, so apps
      # that store file sets under the legacy "FileSet" name get nothing back when asked through it.
      def each_file_set
        return enum_for(:each_file_set) unless block_given?

        seen = Set.new
        query_services.each do |service|
          Hyrax::ModelRegistry.file_set_classes.each do |model|
            service.find_all_of_model(model:).each { |file_set| yield file_set if seen.add?(file_set.id.to_s) }
          end
        end
      end

      # Yields [file_set, original file] for each file set that has an original. A file set whose original
      # cannot be loaded (for example a dangling file record) goes to on_error and is skipped, so one bad
      # record does not stop the run.
      def each_original(limit: nil, progress: nil, on_error: nil)
        return enum_for(:each_original, limit:, progress:, on_error:) unless block_given?

        done = 0
        each_file_set do |file_set|
          break if limit && done >= limit

          progress&.tick
          original = original_for(file_set, on_error:)
          next unless original

          done += 1 if yield(file_set, original)
        end
      end

      def original_for(file_set, on_error: nil)
        Hyrax.custom_queries.find_original_file(file_set:)
      rescue StandardError => e
        on_error&.call(file_set, e)
        nil
      end

      def query_services
        service = Hyrax.query_service
        services = service.respond_to?(:services) ? service.services : [service]
        services.reject { |inner| defined?(Wings::Valkyrie::QueryService) && inner.is_a?(Wings::Valkyrie::QueryService) }
      end
    end
  end
end
