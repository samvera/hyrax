class User < ActiveRecord::Base
  # Adds acts_as_messageable for user mailboxes
  include Mailboxer::Models::Messageable
  # Connects this user object to Blacklight's Bookmarks and Folders.
  include Blacklight::User

  delegate :can?, :cannot?, :to => :ability

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
  attr_accessible :email, :login, :display_name, :address, :admin_area, :department, :title, :office, :chat_id, :website, :affiliation, :telephone, :avatar

  # Add user avatar (via paperclip library)
  has_attached_file :avatar, :styles => { medium: "300x300>", thumb: "100x100>" }, :default_url => ActionController::Base.helpers.asset_path('missing_:style.png')
  validates :avatar, :attachment_content_type => { :content_type => /^image\/(jpg|jpeg|pjpeg|png|x-png|gif)$/ }, :if => Proc.new { |p| p.avatar.file? }
  validates :avatar, :attachment_size => { :less_than => 500.kilobytes }, :if => Proc.new { |p| p.avatar.file? }

  # This method should display the unique identifier for this user as defined by devise.
  # The unique identifier is what access controls will be enforced against.
  def user_key
    send(Devise.authentication_keys.first)
  end

  def to_s
    login
  end

  def name
    return self.display_name.titleize || self.login rescue self.login
  end

  # Redefine this for more intuitive keys in Redis
  def to_param
    login
  end

  # method needed for messaging
  def mailboxer_email(obj=nil)
    return nil
  end

  # Groups that user is a member of
  def groups
    self.class.groups(login) rescue []
  end

  def self.groups(login)
    Hydra::LDAP.groups_for_user(Net::LDAP::Filter.eq('uid', login))  { |result| result.first[:psmemberof].select{ |y| y.starts_with? 'cn=umg/' }.map{ |x| x.sub(/^cn=/, '').sub(/,dc=psu,dc=edu/, '') } } rescue []
  end

  def populate_attributes
    begin
      entry = directory_attributes.first
    rescue
      logger.warn "Directory entry not found for user '#{login}'"
      return
    end
    attrs = {}
    attrs[:email] = entry[:mail].first rescue nil
    attrs[:display_name] = entry[:displayname].first rescue nil
    attrs[:address] = entry[:postaladdress].first.gsub('$', "\n") rescue nil
    attrs[:admin_area] = entry[:psadminarea].first rescue nil
    attrs[:department] = entry[:psdepartment].first rescue nil
    attrs[:title] = entry[:title].first rescue nil
    attrs[:office] = entry[:psofficelocation].first.gsub('$', "\n") rescue nil
    attrs[:chat_id] = entry[:pschatname].first rescue nil
    attrs[:website] = entry[:labeleduri].first.gsub('$', "\n") rescue nil
    attrs[:affiliation] = entry[:edupersonprimaryaffiliation].first rescue nil
    attrs[:telephone] = entry[:telephonenumber].first rescue nil
    update_attributes(attrs)
  end

  def directory_attributes(attrs=[])
    self.class.directory_attributes(login, attrs)
  end

  def self.directory_attributes(login, attrs=[])
    Hydra::LDAP.get_user(Net::LDAP::Filter.eq('uid', login), attrs)
  end

  def ability
    @ability ||= Ability.new(self)
  end

  def self.current
    Thread.current[:user]
  end

  def self.current=(user)
    Thread.current[:user] = user
  end
end
