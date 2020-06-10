# frozen_string_literal: true
module Hyrax
  # Grants the user's read access on the provided FileSet
  class GrantReadJob < ApplicationJob
    include PermissionJobBehavior
    # @param file_set_id [String] the identifier of the object to grant access to
    # @param user_key [String] the user to add
    # @param use_valkyrie [Boolean] use valkyrie resources for this operation?
    def perform(file_set_id, user_key, use_valkyrie: Hyrax.config.use_valkyrie?)
      if use_valkyrie
        acl(file_set_id).grant(:read).to(user(user_key)).save
      else
        file_set = ::FileSet.find(file_set_id)
        file_set.read_users += [user_key]
        file_set.save!
      end
    end
  end
end
