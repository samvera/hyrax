module Hyrax
  ##
  # @abstract Propogates visibility from a provided object (e.g. a Work) to some
  # group of its members (e.g. file_sets).
  class VisibilityPropagator
    ##
    # @param source [#visibility] the object to propogate visibility from
    #
    # @return [#propogate]
    def self.for(source:)
      FileSetVisibilityPropagator.new(source: source)
    end
  end
end
