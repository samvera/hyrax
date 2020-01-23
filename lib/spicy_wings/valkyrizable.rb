# frozen_string_literal: true

module SpicyWings
  ##
  # A mixin for `ActiveFedora::Base` models providing a convenience method
  # mapping to a valkyrie resource.
  #
  # @example
  #   GenericWork.include SpicyWings::Valkyrizable
  #
  #   work     = GenericWork.new(title: ['Comet in Moominland'])
  #   resource = work.valkyrie_resource
  #
  #   resource.title # => ['Comet in Moominland']
  #
  # @see SpicyWings::ModelTransformer
  module Valkyrizable
    ##
    # @return [Valkyrie::Resource] a valkyrie resource matching this model
    def valkyrie_resource
      ModelTransformer.for(self)
    end
  end
end
