# frozen_string_literals: true

module Hyrax
  class WorkChangeSetPersister < ChangeSetPersister
    before_delete :cleanup_file_sets

    # Deletes all file_sets that are members of the resource in the supplied change_set
    # @param [Hyrax::WorkChangeSet] the change_set that contains the resource whose member file_sets you wish to delete
    def cleanup_file_sets(change_set:)
      file_set_members = metadata_adapter.query_service.find_members(resource: change_set.resource, model: ::FileSet)
      change_sets = file_set_members.map do |file_set|
        Hyrax::FileSetChangeSet.new(file_set)
      end
      FileChangeSetPersister.new(metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister), storage_adapter: Valkyrie.config.storage_adapter).delete_all(change_sets: change_sets)
    end
  end
end
