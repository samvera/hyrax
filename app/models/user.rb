Devise.add_module(:http_header_authenticatable,
  :strategy => true,
  :controller => :sessions,
  :model => 'devise/models/http_header_authenticatable')

class User < ActiveRecord::Base
  # Connects this user object to Hydra behaviors. 
  include Hydra::User
  # Connects this user object to Blacklights Bookmarks and Folders. 
  include Blacklight::User
  devise :http_header_authenticatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :login, :email

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account. 
  def to_s
    read_attribute :login
  end

  # Groups that user is a member of
  def groups 
    Hydra::LDAP.groups_for_user(login + ",dc=psu,dc=edu")
  end

end
