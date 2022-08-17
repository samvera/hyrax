# frozen_string_literal: true

module Hyrax
  ##
  # Defines a map from a visibility string value to appropriate permissions
  # representing that visibility.
  #
  # @see Hyrax::VisibilityReader
  # @see Hyrax::VisibilityWriter
  # @see Hyrax::Resource#visibility
  class VisibilityMap
    DEFAULT_MAP = {
      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC => {
        permission: Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC,
        additions: [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC].freeze,
        deletions: [].freeze
      }.freeze,
      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED => {
        permission: Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED,
        additions: [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED].freeze,
        deletions: [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC].freeze
      }.freeze,
      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE => {
        permission: :PRIVATE,
        additions: [].freeze,
        deletions: [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC,
                    Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED].freeze
      }.freeze
    }.freeze

    extend Forwardable
    include Singleton

    def_delegators :@map, :[]

    ##
    # @!attribute [r] map
    #   @return [Hash<String, Hash>]
    attr_reader :map

    ##
    # @param map [Hash<String, String>]
    def initialize(map: DEFAULT_MAP)
      @map = map
    end

    ##
    # Reverse lookup a visibility stirng from the permission group value
    def visibility_for(group:)
      @map.find { |_, v| v[:permission] == group }&.first
    end

    def additions_for(visibility:)
      fetch(visibility)&.fetch(:additions)
    end

    def deletions_for(visibility:)
      fetch(visibility)&.fetch(:deletions)
    end

    def fetch(key, &block)
      @map.fetch(key, &block)
    rescue KeyError => e
      raise(UnknownVisibility, e.message)
    end

    def visibilities
      @map.keys
    end

    class UnknownVisibility < KeyError; end
  end
end
