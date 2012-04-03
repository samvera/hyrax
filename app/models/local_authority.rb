class LocalAuthority < ActiveRecord::Base
  has_and_belongs_to_many :domain_terms
  has_many :local_authority_entries
end
