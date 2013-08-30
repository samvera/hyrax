class LocalAuthorityEntry < ActiveRecord::Base
  belongs_to :local_authority
  deprecated_attr_accessible  :local_authority, :label, :uri
end
