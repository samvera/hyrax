module Hyrax
  # Revokes the user's edit access on the provided FileSet
  class RevokeEditJob < ApplicationJob
    queue_as Hyrax.config.ingest_queue_name

    # @param [Valkyrie::ID] file_set_id - the identifier of the object to revoke access from
    # @param [String] user_key - the user to remove
    def perform(file_set_id, user_key)
      file_set = Hyrax::Queries.find_file_set(id: file_set_id)
      change_set = Hyrax::FileSetChangeSet.new(file_set)
      params = { edit_users: (file_set.edit_users - [user_key]),
                 search_context: SearchContext.new(::User.find_by_user_key(file_set.depositor)) }
      raise "Unable to update file set. #{file_change_set.errors.messages}" unless change_set.validate(params)
      change_set.sync
      change_set_persister.save(change_set: change_set)
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
end
