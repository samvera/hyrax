module Hyrax
  class VersioningService
    # Make a version and record the version committer
    # @param [ActiveFedora::File] content
    # @param [User, String] user
    def self.create(content, user = nil)
      new_version = content.new(id: nil)
      new_version.label = "version#{content.member_ids.length + 1}"
      new_version = indexing_adapter.persister.save(resource: new_version)
      content.member_ids = content.member_ids + [new_version.id]
      content = indexing_adapter.persister.save(resource: content)
      record_committer(content, user) if user
    end

    # @param [ActiveFedora::File] file
    def self.latest_version_of(file)
      file.versions.last
    end

    # Record the version committer of the last version
    # @param [ActiveFedora::File] content
    # @param [User, String] user_key
    def self.record_committer(content, user_key)
      user_key = user_key.user_key if user_key.respond_to?(:user_key)
      version = latest_version_of(content)
      return if version.nil?
      VersionCommitter.create(version_id: version.id.to_s, committer_login: user_key)
    end

    def self.restore_version(file_set, content, revision_id, user = nil)
      found_version = content.versions.find { |x| x.label == Array.wrap(revision_id) }
      return unless found_version
      node = Hyrax::FileNodeBuilder.new(storage_adapter: nil, persister: indexing_adapter.persister).attach_file_node(node: found_version, file_set: file_set)
      create(node, user)
    end

    def self.indexing_adapter
      Valkyrie::MetadataAdapter.find(:indexing_persister)
    end
  end
end
