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
    # @!attribute [rw] resource
    #   @return [Valkyrie::Resource::AccessControls]
    attr_accessor :resource

    ##
    # @param resource [Valkyrie::Resource::AccessControls]
    def initialize(resource:)
      self.resource = resource
    end

    ##
    # @param visibility [String]
    #
    # @return [void]
    def assign_access_for(visibility:)
      resource.read_groups -= visibility_map.deletions_for(visibility: visibility)
      resource.read_groups += visibility_map.additions_for(visibility: visibility)
    end

    def visibility_map
      Hyrax::VisibilityMap.instance
    end
  end
end
