# frozen_string_literal: true

module Hyrax
  ##
  # A list of permissions pertaining to a specific object.
  class AccessControl < Valkyrie::Resource
    ##
    # @!attribute [rw] access_to
    #   Supports query for ACLs at the resource level. Permissions should be
    #   grouped under an AccessControl with a matching `#access_to` so they can
    #   be retrieved in batch.
    #
    #   @return [Valkyrie::ID] the id of the Resource these permissions apply to
    # @!attribute [rw] permissions
    #   @return [Enumerable<Hyrax::Permission>]
    attribute :access_to,   Valkyrie::Types::ID
    attribute :permissions, Valkyrie::Types::Set
  end
end
