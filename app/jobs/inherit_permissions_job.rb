# A job to apply work permissions to all contained files set
#
class InheritPermissionsJob < Hyrax::ApplicationJob
  # Perform the copy from the work to the contained filesets
  #
  # @param work containing access level and filesets
  def perform(work)
    file_sets = Hyrax::Queries.find_members(resource: work, model: ::FileSet)
    change_set_persister.buffer_into_index do |persister|
      file_sets.each do |file_set|
        change_set = Hyrax::FileSetChangeSet.new(file_set)
        params = { read_users: work.read_users, read_groups: work.read_groups,
                   edit_users: work.edit_users, edit_groups: work.edit_groups,
                   search_context: SearchContext.new(::User.find_by_user_key(file_set.depositor)) }
        raise "Unable to update file set. #{change_set.errors.messages}" unless change_set.validate(params)
        change_set.sync
        persister.save(change_set: change_set)
      end
    end
  end

  private

    def change_set_persister
      Hyrax::FileSetChangeSetPersister.new(
        metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
        storage_adapter: Valkyrie.config.storage_adapter
      )
    end

    class SearchContext
      def initialize(user = nil)
        @user = user
      end
      attr_reader :user
    end
end
