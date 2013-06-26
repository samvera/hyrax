class LocalAuthorityEntry < ActiveRecord::Base
  belongs_to :local_authority
  attr_accessible :local_authority, :label, :uri if Rails::VERSION::MAJOR == 3
end
