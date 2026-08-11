# frozen_string_literal: true

module Qa::Authorities
  ##
  # @api public
  #
  # "Did you mean" authority for the `linked_record` compound picker's create-form
  # duplicate check, mounted at `/authorities/search/linked_record_similar/:source`.
  # Sibling of {Qa::Authorities::LinkedRecord} (the typeahead authority): the
  # `:source` URL segment arrives as `params[:subauthority]` (QA's standard
  # `/search/:vocab(/:subauthority)` route), and the typed name is delegated to
  # that registered {Hyrax::CompoundLinkedRecordResolver} source's `similar` proc,
  # so a single authority serves every source.
  #
  # Returns `{ id:, label:, value: }` rows (the same shape as the typeahead), or
  # `[]` when the source is missing, unregistered, or declares no `similar` proc.
  class LinkedRecordSimilar < Qa::Authorities::Base
    def search(query, controller)
      source = controller.params[:subauthority].to_s
      return [] if source.empty?

      Hyrax::CompoundLinkedRecordResolver.similar(source, query)
    end
  end
end
