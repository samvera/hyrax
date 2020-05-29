# frozen_string_literal: true

module Hyrax
  module Actors
    ##
    # @note this is effectively an alias for AbstractActor; it exists to
    #   communicate to readers that this actor is intended to be a concrete,
    #   do-nothing actor (and also in case `AbstractActor` ever becomes actually
    #   abstract).
    class NullActor < AbstractActor; end
  end
end
