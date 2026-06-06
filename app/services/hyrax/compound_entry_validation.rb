# frozen_string_literal: true

module Hyrax
  ##
  # @api public
  #
  # Pure validation logic for a single compound's entries, decoupled from
  # ActiveModel and Reform so it can be reused (e.g. a future Bulkrax-side
  # check) and unit-tested directly. {Hyrax::CompoundEntryValidator} wraps this
  # for the form layer. See documentation/forms/compound_fields.md.
  #
  # Rules (driven by the normalized definition from {Hyrax::CompoundSchema}):
  #   * a compound marked `required` must have at least one populated row;
  #   * every populated row must fill all of the compound's `required`
  #     sub-properties.
  #
  # Rows are the post-populator persisted hashes (all-blank rows already
  # dropped), so a no-required compound with no rows is valid.
  class CompoundEntryValidation
    # @param definition [Hash] the normalized compound definition
    # @param entries [Array<Hash>] the compound's persisted rows
    def initialize(definition, entries)
      @definition = definition || {}
      @entries = Array(entries)
    end

    # @return [Array<Hash>] one violation per problem, each
    #   `{ type:, missing: [keys] }`. Empty when the compound is valid.
    #   `type` is `:required_but_empty` or `:missing_required_subproperties`.
    def violations
      return [{ type: :required_but_empty, missing: required_keys }] if required_but_empty?

      rows_missing_required.map { |missing| { type: :missing_required_subproperties, missing: missing } }
    end

    # @return [Boolean]
    def valid?
      violations.empty?
    end

    private

    attr_reader :definition, :entries

    def required_keys
      definition.fetch(:subproperties, {}).select { |_k, spec| spec[:required] }.keys
    end

    def required_but_empty?
      definition[:required] && populated_rows.empty?
    end

    # The set of required keys missing from each populated row that omits any of
    # them (one entry per offending row; deduped so identical gaps collapse to
    # one message).
    def rows_missing_required
      return [] if required_keys.empty?

      populated_rows.filter_map do |row|
        missing = required_keys.reject { |key| value_present?(row, key) }
        missing unless missing.empty?
      end.uniq
    end

    def populated_rows
      entries.select { |row| row.is_a?(::Hash) && row.values.any?(&:present?) }
    end

    def value_present?(row, key)
      (row[key] || row[key.to_sym]).present?
    end
  end
end
