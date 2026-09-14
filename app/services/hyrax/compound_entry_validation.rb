# frozen_string_literal: true

module Hyrax
  ##
  # @api public
  #
  # Pure validation logic for a single compound's entries, decoupled from
  # ActiveModel and Reform so it can be reused (e.g. a future Bulkrax-side
  # check) and unit-tested directly. {Hyrax::CompoundEntryValidator} wraps this
  # for the form layer. See documentation/compound_fields.md.
  #
  # Rules (driven by the normalized definition from {Hyrax::CompoundSchema}):
  #   * a compound marked `required` must have at least one populated row;
  #   * every populated row must fill all of the compound's `required`
  #     sub-properties;
  #   * a declared `ordered` rule (`validations: [{ type: ordered, before:, after: }]`)
  #     requires `after` to be greater than or equal to `before` in every row that
  #     supplies both comparable values.
  #
  # Rows are the post-populator persisted hashes (all-blank rows already
  # dropped), so a no-required compound with no rows is valid.
  class CompoundEntryValidation
    # The `validations` rule types this class implements.
    # {Hyrax::FlexibleSchemaValidators::CompoundValidationsValidator} warns about
    # anything absent here, so adding a rule means adding its type here too or
    # profiles using it will warn.
    RULE_TYPES = %w[ordered].freeze

    # @param definition [Hash] the normalized compound definition
    # @param entries [Array<Hash>] the compound's persisted rows
    def initialize(definition, entries)
      @definition = definition || {}
      @entries = Array(entries)
    end

    # @return [Array<Hash>] one violation per problem, each
    #   `{ type:, missing: [keys] }`. Empty when the compound is valid.
    #   `type` is `:required_but_empty`, `:missing_required_subproperties`, or
    #   `:out_of_order`.
    def violations
      return [{ type: :required_but_empty, missing: required_keys }] if required_but_empty?

      missing = rows_missing_required.map { |keys| { type: :missing_required_subproperties, missing: keys } }
      # An unfinished row cannot be compared, so the required-field error stands alone.
      return missing if missing.any?

      ordering_violations
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

    # One violation per declared rule, not per offending row, as with
    # missing_required_subproperties: the depositor needs the rule named once.
    def ordering_violations
      ordered_rules.filter_map do |rule|
        next if rows_out_of_order(rule).empty?

        { type: :out_of_order, missing: [rule[:after]] }
      end
    end

    def ordered_rules
      Array(definition[:validations]).select do |rule|
        rule[:type].to_s == 'ordered' && rule[:before].present? && rule[:after].present?
      end
    end

    def rows_out_of_order(rule)
      populated_rows.select do |row|
        before = comparable(row, rule[:before])
        after = comparable(row, rule[:after])

        before && after && after < before
      end
    end

    # Dates only: `ordered` is currently a date rule, so a value that does not parse
    # (blank, or a partial/free-text date the profile permits) is skipped rather than
    # flagged. Comparing other types would mean declaring the type in the rule.
    def comparable(row, key)
      value = row[key] || row[key.to_sym]
      return if value.blank?

      Date.parse(value.to_s)
    rescue ArgumentError, TypeError
      nil
    end

    def value_present?(row, key)
      (row[key] || row[key.to_sym]).present?
    end
  end
end
