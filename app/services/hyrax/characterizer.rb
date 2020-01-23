module Hyrax
  ##
  # @abstract Propogates visibility from a provided object (e.g. a Work) to some
  # group of its members (e.g. file_sets).
  class Characterizer
    ##
    # @param source [#visibility] the object to propogate visibility from
    #
    # @return [#propogate]
    def self.for(source:)
      case source
      when Hyrax::FileSetBehavior # ActiveFedora
        FileSetCharacterizer.new(source: source)
      when Hyrax::Resource # Valkyrie
        byebug
        ResourceVisibilityPropagator.new(source: source)
      end
    end
  end
end
