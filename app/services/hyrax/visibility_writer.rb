# frozen_string_literal: true

module Hyrax
  ##
  # Sets ACLs from a visibility string
  #
  # @example
  #   resource = Hyrax::Resource.new
  #   writer   = Hyrax::VisibilityWriter.new(resource: resource)
  #   resource.read_groups # => []
  #
  #   writer.assign_access_for(visibility: 'open')
  #   resource.read_groups # => ["public"]
  #
  #   writer.assign_access_for(visibility: 'authenticated')
  #   resource.read_groups # => ["registered"]
  #
  class VisibilityWriter
    ##
    # @!attribute [r] permission_manager
    #   @return [Hyrax::PermissionManager]
    # @!attribute [rw] resource
    #   @return [Valkyrie::Resource]
    attr_accessor :resource
    attr_reader   :permission_manager

    ##
    # @param resource [Valkyrie::Resource]
    def initialize(resource:)
      self.resource       = resource
      @permission_manager = resource.permission_manager
    end

    ##
    # @param visibility [String]
    #
    # @return [void]
    def assign_access_for(visibility:)
      permission_manager.read_groups =
        permission_manager.read_groups.to_a - visibility_map.deletions_for(visibility: visibility)

      permission_manager.read_groups =
        permission_manager.read_groups.to_a + visibility_map.additions_for(visibility: visibility)
    end

    def visibility_map
      Hyrax.config.visibility_map
    end
  end
end
