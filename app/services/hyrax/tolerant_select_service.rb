# frozen_string_literal: true
module Hyrax
  ##
  # A more tolerant `QaSelectService`. This service treats terms with no
  # `active:` property as active terms, instead of erroring with `eKeyError`.
  class TolerantSelectService < QaSelectService
    ##
    # @return [Boolean] indicates whether the term is active;
    #   false if the term is inactive or is not present in the authority;
    #   defaults to true when the term is present but no `active:` key is given.
    def active?(id)
      result = authority.find(id)
      return false if result.blank?
      result.fetch('active', true)
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
