class DomainTerm < ActiveRecord::Base
  deprecated_attr_accessible  :model, :term

  # TODO we should add an index on this join table and remove the uniq query
  if Rails::VERSION::MAJOR > 3
    has_and_belongs_to_many :local_authorities, -> {uniq}
  else
    has_and_belongs_to_many :local_authorities, :uniq=> true 
  end
end
