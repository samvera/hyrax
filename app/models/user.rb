class User < ActiveRecord::Base
  # Adds acts_as_messageable for user mailboxes
  include Mailboxer::Models::Messageable
  # Connects this user object to Blacklights Bookmarks and Folders.
  include Blacklight::User

  Devise.add_module(:http_header_authenticatable,
                    :strategy => true,
                    :controller => :sessions,
                    :model => 'devise/models/http_header_authenticatable')

  devise :http_header_authenticatable

  # set this up as a messageable object
  acts_as_messageable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :login

  # This method should display the unique identifier for this user as defined by devise.
  # The unique identifier is what access controls will be enforced against.
  def user_key
    send(Devise.authentication_keys.first)
  end

  def to_s
    login
  end
  alias_method :name, :to_s

  # method needed for messaging
  def mailboxer_email(obj=nil)
    return nil
  end

  # Groups that user is a member of
  def groups
    ScholarSphere::LDAP.groups_for_user(login) rescue []
  end

  def self.current
    Thread.current[:user]
  end

  def self.current=(user)
    Thread.current[:user] = user
  end
end
