module Hyrax
  class OrcidValidator < ActiveModel::Validator
    def validate(record)
      return if record.orcid.blank?
      record.errors.add(:orcid, 'must be a string of 19 characters, e.g., "0000-0000-0000-0000"') unless self.class.match(record.orcid)
    end

    def self.match(string)
      Regexp.new(orcid_regex).match(string) { |m| m[:orcid] }
    end

    def self.orcid_regex
      '^(?<prefix>https?://orcid.org/)?(?<orcid>\d{4}-\d{4}-\d{4}-\d{3}[\dX])/?$'
    end
    private_class_method :orcid_regex
  end
end
