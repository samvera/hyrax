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
    # @!attribute [rw] resource
    #   @return [Valkyrie::Resource::AccessControls]
    attr_accessor :resource

    ##
    # @param resource [Valkyrie::Resource::AccessControls]
    def initialize(resource:)
      self.resource = resource
    end

    ##
    # @return [String]
    def read
      if resource.read_groups.include? Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC
        visibility_map.visibility_for(group: Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC)
      elsif resource.read_groups.include? Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED
        visibility_map.visibility_for(group: Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED)
      else
        visibility_map.visibility_for(group: :PRIVATE)
      end
    end

    def visibility_map
      Hyrax::VisibilityMap.instance
    end
  end
end
