class DomainTerm < ActiveRecord::Base
  attr_accessible :model, :term if Rails::VERSION::MAJOR == 3

  # TODO we should add an index on this join table and remove the uniq query
  has_and_belongs_to_many :local_authorities, :uniq=> true 
end
