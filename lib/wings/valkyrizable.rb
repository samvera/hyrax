# frozen_string_literal: true

module Wings
  ##
  # A mixin for `ActiveFedora::Base` models providing a convenience method
  # mapping to a valkyrie resource.
  #
  # @example
  #   GenericWork.include Wings::Valkyrizable
  #
  #   work     = GenericWork.new(title: ['Comet in Moominland'])
  #   resource = work.valkyrie_resource
  #
  #   resource.title # => ['Comet in Moominland']
  #
  # @see Wings::ModelTransformer
  module Valkyrizable
    ##
    # @return [Valkyrie::Resource] a valkyrie resource matching this model
    def valkyrie_resource
      ModelTransformer.for(self)
    end
  end
end
