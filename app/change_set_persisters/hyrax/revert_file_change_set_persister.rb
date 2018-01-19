# frozen_string_literals: true

module Hyrax
  # responsible for reverting to an old version of a File
  class RevertFileChangeSetPersister < ChangeSetPersister
    # TODO: this is not yet implemented because we have to implement versions
    #       before we can revert to a version.
    def save(change_set:)
      file_set = change_set.resource
      return false unless Hyrax::VersioningService.restore_version(file_set, related_file(file_set), change_set.revision, change_set.user)
      Hyrax.config.callback.run(:after_revert_content, change_set.resource, change_set.user, change_set.revision)
      super
    end

    private

      # @return [Hyrax::FileNode] the file referenced by relation
      def related_file(file_set)
        file_set.member_by(use: relation) || raise("No #{relation} returned for FileSet #{file_set.id}")
      end

      def relation
        Valkyrie::Vocab::PCDMUse.OriginalFile
      end
  end
end
