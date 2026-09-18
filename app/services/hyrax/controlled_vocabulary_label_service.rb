# frozen_string_literal: true

module Hyrax
  ##
  # Resolves a controlled vocabulary term's id to its human-readable label.
  #
  # Hyrax has no vocabulary store of its own, so this is the seam: the default
  # resolves nothing and Hyrax behaves exactly as it did before, while an
  # application registers a real implementation on
  # {Hyrax::Configuration#controlled_vocabulary_label_service}. A replacement
  # need only respond to the two methods below.
  #
  # @example registering an application's own resolver
  #   Hyrax.config.controlled_vocabulary_label_service = MyLabelService.new
  class ControlledVocabularyLabelService
    ##
    # One entry per value, in the order given: the term's label, or the value
    # itself where the authority does not know it. Implementations must stay
    # positional — the renderer pairs values to labels, so an unresolved value
    # has to hold its place. Never compact the result.
    #
    # @param source [String] the name of the controlled vocabulary
    # @param values [Array, Object, nil] the stored term ids
    # @return [Array]
    def labels_for(_source, values)
      Array.wrap(values)
    end

    ##
    # Whether labels can be resolved for the named vocabulary; a property whose
    # authority is not resolvable keeps its ids alone. Answer false for remote
    # authorities — resolving one means a network call per value, which has no
    # place in an indexing run.
    #
    # @param source [String]
    # @return [Boolean]
    def resolvable?(_source)
      false
    end
  end
end
