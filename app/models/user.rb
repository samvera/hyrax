class User < ActiveRecord::Base
  # Adds acts_as_messageable for user mailboxes
  include Mailboxer::Models::Messageable
  # Connects this user object to Blacklight's Bookmarks and Folders.
  include Blacklight::User

  Devise.add_module(:http_header_authenticatable,
                    :strategy => true,
                    :controller => :sessions,
                    :model => 'devise/models/http_header_authenticatable')

  devise :http_header_authenticatable

  # set this up as a messageable object
  acts_as_messageable

  # Users should be able to follow things
  acts_as_follower
  # Users should be followable
  acts_as_followable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :login, :display_name, :address, :admin_area, :department, :title, :office, :chat_id, :website, :affiliation, :telephone

  # This method should display the unique identifier for this user as defined by devise.
  # The unique identifier is what access controls will be enforced against.
  def user_key
    send(Devise.authentication_keys.first)
  end

  def to_s
    login
  end

  def name
    return self.display_name
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

  def populate_attributes
    entry = directory_attributes.first
    attrs = {
      :email => entry[:mail].first,
      :display_name => entry[:displayname].first,
      :address => entry[:postaladdress].first.gsub('$', "\n"),
      :admin_area => entry[:psadminarea].first,
      :department => entry[:psdepartment].first,
      :title => entry[:title].first,
      :office => entry[:psofficelocation].first,
      :chat_id => entry[:pschatname].first,
      :website => entry[:labeleduri].first.gsub('$', "\n"),
      :affiliation => entry[:edupersonprimaryaffiliation].first,
      :telephone => entry[:telephonenumber].first,
    }
    update_attributes(attrs)
  end

  def directory_attributes(attrs=[])
    self.class.directory_attributes(login, attrs)
  end

  def self.directory_attributes(login, attrs=[])
    Hydra::LDAP.get_user(Net::LDAP::Filter.eq('uid', login), attrs)
  end

  def self.current
    Thread.current[:user]
  end

  def self.current=(user)
    Thread.current[:user] = user
  end
end
