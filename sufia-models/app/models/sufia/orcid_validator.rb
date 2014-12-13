module Sufia
  class OrcidValidator < ActiveModel::Validator
    def validate(record)
      return if record.orcid.blank?
      record.errors.add(:orcid, 'must be a string of 19 characters, e.g., "0000-0000-0000-0000"') unless /\d{4}-\d{4}-\d{4}-\d{4}/.match(record.orcid)
    end
  end
end
