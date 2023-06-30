# frozen_string_literal: true

module Hyrax
  ##
  # Translates a set of ACLs into a visibility string.
  #
  # @example
  #   resource = Hyrax::Resource.new
  #   reader   = Hyrax::VisibilityReader.new(resource: resource)
  #   reader.read # => "restricted"
  #
  #   resource.read_groups = ["public"]
  #   reader.read # => "open"
  #
  class VisibilityReader
    ##
    # @!attribute [r] permission_manager
    #   @return [Hyrax::PermissionManager]
    # @!attribute [rw] resource
    #   @return [Valkyrie::Resource]
    attr_reader   :permission_manager
    attr_accessor :resource

    ##
    # @param resource [Valkyrie::Resource::AccessControls]
    def initialize(resource:)
      self.resource = resource
      @permission_manager = resource.permission_manager
    end

    ##
    # @return [String]
    def read
      if permission_manager.read_groups.include? Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC
        visibility_map.visibility_for(group: Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC)
      elsif permission_manager.read_groups.include? Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED
        visibility_map.visibility_for(group: Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED)
      else
        visibility_map.visibility_for(group: :PRIVATE)
      end
    end

    def visibility_map
      Hyrax.config.visibility_map
    end
  end
end
