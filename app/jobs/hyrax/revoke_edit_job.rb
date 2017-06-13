module Hyrax
  # Revokes the user's edit access on the provided FileSet
  class RevokeEditJob < ApplicationJob
    queue_as Hyrax.config.ingest_queue_name

    # @param [String] file_set_id - the identifier of the object to revoke access from
    # @param [String] user_key - the user to remove
    def perform(file_set_id, user_key)
      file_set = ::FileSet.find(file_set_id)
      file_set.edit_users -= [user_key]
      file_set.save!
    end
  end
end
