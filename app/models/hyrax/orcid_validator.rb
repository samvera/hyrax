# frozen_string_literal: true
module Hyrax
  class OrcidValidator < ActiveModel::Validator
    ORCID_REGEXP = %r{^(?<prefix>https?://orcid.org/)?(?<orcid>\d{4}-\d{4}-\d{4}-\d{3}[\dX])/?$}.freeze
    def validate(record)
      return if record.orcid.blank?
      record.errors.add(:orcid, 'must be a string of 19 characters, e.g., "0000-0000-0000-0000"') unless ORCID_REGEXP.match?(record.orcid)
    end

    # @deprecated
    def self.match(string)
      Deprecation.warn "Use 'Hyrax::OrcidValidator.extract_bare_orcid(from:)'"
      extract_bare_orcid_from(from: string)
    end

    # @api public
    # @param [String] from
    # @return nil if the given string is not in the Orcid form
    # @return string of the form "0000-0000-0000-0000" if the given string conforms to Orcid's format
    # @see ORCID_REGEXP
    def self.extract_bare_orcid(from:)
      ORCID_REGEXP.match(from) { |m| m[:orcid] }
    end
  end
end
