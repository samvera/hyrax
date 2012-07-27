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
  #alias_method :name, :to_s

  def name    
    return self.class.display_name(login)
  end

  # method needed for messaging
  def mailboxer_email(obj=nil)
    return nil
  end

  # Groups that user is a member of
  def groups
    self.class.groups(login) 
  end

  def self.groups(login)
    Hydra::LDAP.groups_for_user(Net::LDAP::Filter.eq('uid', login))  { |result| result.first[:psmemberof].select{ |y| y.starts_with? 'cn=umg/' }.map{ |x| x.sub(/^cn=/, '').sub(/,dc=psu,dc=edu/, '') } } rescue []
  end

  def attributes(attributes=[])
    self.class.attributes(login, attributes)
  end

  def self.attributes(login, attributes=[])
    Hydra::LDAP.get_user(Net::LDAP::Filter.eq('uid', login), attributes)
  end

  def self.current
    Thread.current[:user]
  end

  def self.current=(user)
    Thread.current[:user] = user
  end
  
  def self.display_name(login)
    begin
      res = ScholarSphere::LDAP.get_user(login, ["displayname"])
      logger.info "LDAP result = #{res[0].displayname}"
      return res[0].displayname[0].titleize
     rescue        
        return login
     end
  end
end
