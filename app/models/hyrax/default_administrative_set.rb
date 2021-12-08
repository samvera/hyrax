# frozen_string_literal: true
module Hyrax
  # This class stores the id of the default `Hyrax::AdministrativeSet`.  This is
  # used to populate a cache of the default admin set in Hyrax::Configuration.
  #
  # @see Hyrax::Configuration.default_admin_set
  # @see Hyrax::Configuration.default_admin_set_id
  # @see Hyrax::Configuration.reset_default_admin_set
  class DefaultAdministrativeSet < ActiveRecord::Base
    self.table_name = 'hyrax_default_administrative_set'

    class << self
      # Set the default admin set id in the first record.
      # @param default_admin_set_id [String | Valkyrie::ID] id of the new default admin set
      def update(default_admin_set_id:)
        validate_id(default_admin_set_id)
        Hyrax.config.reset_default_admin_set

        # saving default_admin_set_id for the first time
        return new(default_admin_set_id: default_admin_set_id.to_s).save if count.zero?

        # replacing previously saved default_admin_set_id
        existing = first
        existing.default_admin_set_id = default_admin_set_id.to_s
        existing.save
      end

      def save_supported?
        ActiveRecord::Base.connection.table_exists? table_name
      end

      private

      def validate_id(id)
        # The id is validated prior to updating because a bad default admin set
        # will cause lots of problems.
        return true if id.is_a?(String) || id.is_a?(Valkyrie::ID)
        raise ArgumentError, "default_admin_set_id must be a non-blank String or Valkyrie::ID"
      end
    end
  end
end
