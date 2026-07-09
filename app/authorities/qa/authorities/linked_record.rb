# frozen_string_literal: true

module Qa::Authorities
  ##
  # @api public
  #
  # Autocomplete authority for the `linked_record` compound sub-property's
  # picker, mounted at `/authorities/search/linked_record/:source`. The `:source`
  # URL segment arrives as `params[:subauthority]` (QA's standard
  # `/search/:vocab(/:subauthority)` route); the query is delegated to that
  # registered {Hyrax::CompoundLinkedRecordResolver} source's `search` proc, so a
  # single authority serves every source — no per-source authority class.
  #
  # Returns `{ id:, label:, value: }` rows, or `[]` when the source is missing,
  # unregistered, or not searchable.
  class LinkedRecord < Qa::Authorities::Base
    def search(query, controller)
      source = controller.params[:subauthority].to_s
      return [] if source.empty?

      Hyrax::CompoundLinkedRecordResolver.search(source, query)
    end
  end
end
