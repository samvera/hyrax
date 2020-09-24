# frozen_string_literal: true
module Hyrax
  # This "service" ensures that we have a well formed AdminSet.
  #
  # @note For historical reasons, we lazily apply the default admin
  #   set to curation concerns that don't already have an admin set.
  #
  # @see AdminSet
  # @see Hyrax::PermissionTemplate
  # @see Hyrax::Actors::DefaultAdminSetActor
  module EnsureWellFormedAdminSetService
    # @api public
    # @since v3.0.0
    #
    # @param admin_set_id [String, nil]
    #
    # @return [String] an admin_set_id; if you provide a "present"
    #   admin_set_id, this service will return that.
    #
    # @see AdminSet.find_or_create_default_admin_set_id
    def self.call(admin_set_id: nil)
      admin_set_id = admin_set_id.presence || AdminSet.find_or_create_default_admin_set_id
      Hyrax::PermissionTemplate.find_or_create_by!(source_id: admin_set_id)
      admin_set_id
    end
  end
end
