# frozen_string_literal: true
module Hyrax
  module Fixity
    ##
    # @note this inherits `Ldp::NotFonud` for backwards compatibility.
    #   This should be a `RuntimeError` or `ArgumentError` in Hyrax 4.0.
    class MissingContentError < Ldp::NotFound; end
  end
end
