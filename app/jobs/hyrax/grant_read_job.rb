module Hyrax
  # Grants the user's read access on the provided FileSet
  class GrantReadJob < Hyrax::ApplicationJob
    queue_as Hyrax.config.ingest_queue_name

    # @param [String] file_set_id - the identifier of the object to grant access to
    # @param [String] user_key - the user to add
    # @param [Boolean] use_valkyrie - use valkyrie resources for this operation?
    def perform(file_set_id, user_key, use_valkyrie: Hyrax.config.use_valkyrie?)
      if use_valkyrie
        file_set_id = Valkyrie::ID.new(file_set_id)
        file_set_resource = Hyrax.query_service.find_by(id: file_set_id)
        acl = Hyrax::AccessControlList.new(resource: file_set_resource)
        acl.grant(:read).to(::User.find_by_user_key(user_key))
        acl.save
      else
        file_set = ::FileSet.find(file_set_id)
        file_set.read_users += [user_key]
        file_set.save!
      end
    end
  end
end
