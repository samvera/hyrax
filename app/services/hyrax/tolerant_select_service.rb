# frozen_string_literal: true
module Hyrax
  ##
  # A more tolerant `QaSelectService`. This service treats terms with no
  # `active:` property as active terms, instead of erroring with `eKeyError`.
  class TolerantSelectService < QaSelectService
    ##
    # @return [Boolean] indicates whether the term is active;
    #   false if the term is inactive or does not exist; defaults to true when
    #   no key is given
    def active?(id)
      authority.find(id)&.fetch('active', true)
    end

    ##
    # @return [Enumerable<Hash>]
    #
    # @raise [KeyError] when no 'term' value is present for the id
    def active_elements
      authority.all.select { |e| e.fetch('active', true) }
    end
  end
end
