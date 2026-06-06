# frozen_string_literal: true

module Hyrax
  # Shared coercion of a nested-attributes fragment into plain Ruby hashes,
  # used by both {Hyrax::CompoundFieldBehavior} and
  # {Hyrax::RedirectsFieldBehavior}. It only normalizes shape (unwrapping
  # `ActionController::Parameters` via `to_unsafe_h`); the row-drop rules
  # (`_destroy`, blank paths, all-blank rows) and any value normalization stay
  # in each populator.
  module CompoundRowPlumbing
    private

    # The submitted `<name>_attributes` payload as a `{ index => row }` hash.
    def fragment_pairs(fragment)
      return {} if fragment.nil?
      fragment.respond_to?(:to_unsafe_h) ? fragment.to_unsafe_h : fragment.to_h
    end

    # A single row as a plain hash.
    def row_hash(row)
      row.respond_to?(:to_unsafe_h) ? row.to_unsafe_h : row.to_h
    end
  end
end
