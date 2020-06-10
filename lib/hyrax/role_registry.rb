# frozen_string_literal: true
module Hyrax
  # Responsible for registering roles critical for your application.
  # Registering a role is effectively saying "my application logic will not work if this role goes away".
  #
  # @see Sipity::Role
  class RoleRegistry
    # @api public
    # You may develop your application assuming that the 'managing' role will always be present and valid
    MANAGING = 'managing'

    # @api public
    # You may develop your application assuming that the 'approving' role will always be present and valid
    APPROVING = 'approving'

    # @api public
    # You may develop your application assuming that the 'depositing' role will always be present and valid
    DEPOSITING = 'depositing'

    # @api public
    #
    # It is a safe assumption that Hyrax has these magic roles.
    # While the descriptions may be mutable, the names are assumed to exist.
    #
    # @see Sipity::Role for data integrity enforcement
    MAGIC_ROLES = {
      MANAGING => 'Grants access to management tasks',
      APPROVING => 'Grants access to approval tasks',
      DEPOSITING => 'Grants access to depositing tasks'
    }.freeze

    def initialize
      @roles = MAGIC_ROLES.dup
    end

    def add(name:, description:)
      @roles[name.to_s] = description
    end

    def role_names
      @roles.keys.sort
    end

    def registered_role?(name:)
      @roles.key?(name.to_s)
    end

    # @api public
    #
    # Load the registered roles into Sipity::Role
    def persist_registered_roles!
      @roles.each do |name, description|
        Sipity::Role.find_or_create_by!(name: name).tap do |role|
          role.description = description
          role.save!
        end
      end
    end
  end
end
