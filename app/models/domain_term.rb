class DomainTerm < ActiveRecord::Base
  has_and_belongs_to_many :local_authorities, :uniq=> true 
end
