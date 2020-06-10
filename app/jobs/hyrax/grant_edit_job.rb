# frozen_string_literal: true
module Hyrax
  # Grants the user's edit access on the provided FileSet
  class GrantEditJob < ApplicationJob
    include PermissionJobBehavior
    # @param file_set_id [String] the identifier of the object to grant access to
    # @param user_key [String] the user to add
    # @param use_valkyrie [Boolean] whether to use valkyrie support
    def perform(file_set_id, user_key, use_valkyrie: Hyrax.config.use_valkyrie?)
      if use_valkyrie
        acl(file_set_id).grant(:edit).to(user(user_key)).save
      else
        file_set = ::FileSet.find(file_set_id)
        file_set.edit_users += [user_key]
        file_set.save!
      end
    end
  end
end
