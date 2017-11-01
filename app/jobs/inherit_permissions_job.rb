# A job to apply work permissions to all contained files set
#
class InheritPermissionsJob < Hyrax::ApplicationJob
  # Perform the copy from the work to the contained filesets
  #
  # @param work containing access level and filesets
  def perform(work)
    file_sets = Hyrax::Queries.find_members(resource: work, model: ::FileSet)
    file_sets.each do |file|
      file_change_set = Hyrax::FileSetChangeSet.new(file)
      file_change_set.read_users = work.read_users
      file_change_set.read_groups = work.read_groups
      file_change_set.edit_users = work.edit_users
      file_change_set.edit_groups = work.edit_groups
      file_change_set.sync
      change_set_persister.save(change_set: file_change_set)
    end
  end

  private

    def change_set_persister
      Hyrax::ChangeSetPersister.new(
        metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
        storage_adapter: Valkyrie.config.storage_adapter
      )
    end
end
