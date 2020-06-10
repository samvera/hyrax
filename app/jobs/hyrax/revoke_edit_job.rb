# frozen_string_literal: true
module Hyrax
  # Revokes the user's edit access on the provided FileSet
  class RevokeEditJob < ApplicationJob
    include PermissionJobBehavior
    # @param file_set_id [String] the identifier of the object to revoke access from
    # @param user_key [String] the user to remove
    # @param use_valkyrie [Boolean] use valkyrie resources for this operation?
    def perform(file_set_id, user_key, use_valkyrie: Hyrax.config.use_valkyrie?)
      if use_valkyrie
        acl(file_set_id).revoke(:edit).from(user(user_key)).save
      else
        file_set = ::FileSet.find(file_set_id)
        file_set.edit_users -= [user_key]
        file_set.save!
      end
    end
  end
end
