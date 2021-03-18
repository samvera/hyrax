# frozen_string_literal: true

module Hyrax
  class VersioningService
    class << self
      # Make a version and record the version committer
      # @param [ActiveFedora::File | Hyrax::FileMetadata] content
      # @param [User, String] user
      def create(content, user = nil)
        use_valkyrie = content.is_a? Hyrax::FileMetadata
        perform_create(content, user, use_valkyrie)
      end

      # @param [ActiveFedora::File | Hyrax::FileMetadata] content
      def latest_version_of(file)
        file.versions.last
      end

      # @param [ActiveFedora::File | Hyrax::FileMetadata] content
      def versioned_file_id(file)
        versions = file.versions.all
        if versions.present?
          Hyrax.config.translate_uri_to_id.call(versions.last.uri)
        else
          file.id
        end
      end

      # Record the version committer of the last version
      # @param [ActiveFedora::File | Hyrax::FileMetadata] content
      # @param [User, String] user_key
      def record_committer(content, user_key)
        user_key = user_key.user_key if user_key.respond_to?(:user_key)
        version = latest_version_of(content)
        return if version.nil?
        version_id = content.is_a?(Hyrax::FileMetadata) ? version.id.to_s : version.uri
        Hyrax::VersionCommitter.create(version_id: version_id, committer_login: user_key)
      end

      private

      def perform_create(content, user, use_valkyrie)
        use_valkyrie ? perform_create_through_valkyrie(content, user) : perform_create_through_active_fedora(content, user)
      rescue NotImplementedError
        Rails.logger.warn "Declining to create a Version for #{content}; #{self} doesn't support versioning with use_valkyrie: #{use_valkyrie}"
      end

      def perform_create_through_active_fedora(content, user)
        content.create_version
        record_committer(content, user) if user
      end

      def perform_create_through_valkyrie(content, user) # no-op
        raise NotImplementedError
      end
    end
  end
end
