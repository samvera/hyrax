# frozen_string_literal: true

module Hyrax
  ##
  # A list of child work types a user may choose to attach for a given work type
  #
  # These lists are used when users select among work types to attach to an
  # existing work, e.g. from Actions available on the show view.
  #
  # @example
  #   child_types = Hyrax::ChildTypes.for(parent: MyWorkType)
  #
  class ChildTypes
    include Enumerable
    extend Forwardable

    def_delegators :@types, :each

    ##
    # @!attribute [r] types
    #   @return [Array<Class>]
    attr_reader :types

    ##
    # @params [Class] parent
    # @return [Enumerable<Class>] a list of classes that are valid as child types for `parent`
    def self.for(parent:)
      return new(parent.valid_child_concerns) if
        parent.respond_to?(:valid_child_concerns)

      new([parent])
    end

    ##
    # @param [Array<Class>] types
    def initialize(types)
      @types = types.to_a
    end
  end
end
