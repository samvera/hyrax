module Sufia
  class VersioningService
    # Make a version and record the version committer
    # @param [ActiveFedora::File] content
    # @param [User] user
    def self.create(content, user=nil)
      content.create_version
      record_committer(content, user) if user
    end

    # @param [ActiveFedora::File] file
    def self.latest_version_of(file)
      file.versions.last
    end

    protected

      # Record the version committer of the last version
      # @param [ActiveFedora::File] content
      # @param [User] user
      def self.record_committer(content, user)
        version = latest_version_of(content)
        return if version.nil?
        VersionCommitter.create(version_id: version.uri, committer_login: user.user_key)
      end
  end
end
