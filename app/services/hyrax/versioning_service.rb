require 'wings/services/file_metadata_builder'

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
          Hyrax::Base.uri_to_id(versions.last.uri)
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

      # TODO: WINGS - Copied from valkyrie6 branch.  Need to explore whether this is needed?
      # # @param [FileSet] file_set
      # # @param [Hyrax::FileMetadata] content
      # # @param [String] revision_id
      # # @param [User, String] user
      # def restore_version(file_set, content, revision_id, user = nil)
      #   found_version = content.versions.find { |x| x.label == Array.wrap(revision_id) }
      #   return unless found_version
      #   file_metadata = Wings::FileMetadataBuilder.new(storage_adapter: nil, persister: indexing_adapter.persister).attach_file_metadata(file_metadata: found_version, file_set: file_set)
      #   create(file_metadata, user)
      # end

      private

      # # TODO: WINGS - Should we create and use indexing adapter for persistence?  This is what was used in branch valkyrie6.  See issue #3800.
      # def indexing_adapter
      #   Valkyrie::MetadataAdapter.find(:indexing_persister)
      # end

      def perform_create(content, user, use_valkyrie)
        use_valkyrie ? perform_create_through_valkyrie(content, user) : perform_create_through_active_fedora(content, user)
      end

      def perform_create_through_active_fedora(content, user)
        content.create_version
        record_committer(content, user) if user
      end

      def perform_create_through_valkyrie(content, user)
        return # TODO: WINGS - Just return for now.  This method won't work until #indexing_adapter method is complete.  See issue #3800.
        # rubocop:disable Lint/UnreachableCode
        new_version = content.new(id: nil)
        new_version.label = "version#{content.member_ids.length + 1}"
        new_version = indexing_adapter.persister.save(resource: new_version)
        content.member_ids = content.member_ids + [new_version.id]
        content = indexing_adapter.persister.save(resource: content)
        record_committer(content, user) if user
        # rubocop:enable Lint/UnreachableCode
      end
    end
  end
end
