module Hyrax
  # Revokes the user's edit access on the provided FileSet
  class RevokeEditJob < Hyrax::ApplicationJob
    queue_as Hyrax.config.ingest_queue_name

    # @param [String] file_set_id - the identifier of the object to revoke access from
    # @param [String] user_key - the user to remove
    def perform(file_set_id, user_key, use_valkyrie: Hyrax.config.use_valkyrie?)
      if use_valkyrie
        file_set_resource = Hyrax.query_service.find_by(id: file_set_id)
        acl = Hyrax::AccessControlList.new(resource: file_set_resource)
        acl.revoke(:edit).from(::User.find_by_user_key(user_key))
        acl.save
      else
        file_set = ::FileSet.find(file_set_id)
        file_set.edit_users -= [user_key]
        file_set.save!
      end
    end
  end
end
