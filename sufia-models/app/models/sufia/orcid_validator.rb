module Sufia
  class OrcidValidator < ActiveModel::Validator
    def validate(record)
      return if record.orcid.blank?
      record.errors.add(:orcid, 'must be a string of 19 characters, e.g., "0000-0000-0000-0000"') unless self.class.match(record.orcid)
    end

    def self.match(string)
      /\d{4}-\d{4}-\d{4}-\d{3}[\dX]/.match(string)
    end
  end
end
