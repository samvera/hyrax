module Hyrax
  # Grants the user's edit access on the provided FileSet
  class GrantEditJob < ApplicationJob
    queue_as Hyrax.config.ingest_queue_name

    # @param [String] file_set_id - the identifier of the object to grant access to
    # @param [String] user_key - the user to add
    def perform(file_set_id, user_key, use_valkyrie: Hyrax.config.use_valkyrie?)
      if use_valkyrie
        id = Valkyrie::ID.new(file_set_id)
        file_set_resource = Hyrax.query_service.find_by(id: id)
        permissions = PermissionManager.new(resource: file_set_resource)
        permissions.edit_users = permissions.edit_users.to_a.push user_key
        permissions.acl.save
      else
        file_set = ::FileSet.find(file_set_id)
        file_set.edit_users += [user_key]
        file_set.save!
      end
    end
  end
end
