module Sufia::User
  extend ActiveSupport::Concern

  included do
    # Adds acts_as_messageable for user mailboxes
    include Mailboxer::Models::Messageable
    # Connects this user object to Blacklight's Bookmarks and Folders.
    include Blacklight::User
    include Hydra::User

    delegate :can?, :cannot?, to: :ability

    # set this up as a messageable object
    acts_as_messageable

    # Users should be able to follow things
    acts_as_follower
    # Users should be followable
    acts_as_followable

    # Set up proxy-related relationships
    has_many :proxy_deposit_requests, foreign_key: 'receiving_user_id'
    has_many :deposit_rights_given, foreign_key: 'grantor_id', class_name: 'ProxyDepositRights', dependent: :destroy
    has_many :can_receive_deposits_from, through: :deposit_rights_given, source: :grantee
    has_many :deposit_rights_received, foreign_key: 'grantee_id', class_name: 'ProxyDepositRights', dependent: :destroy
    has_many :can_make_deposits_for, through: :deposit_rights_received, source: :grantor

    # Validate and normalize ORCIDs
    validates_with OrcidValidator
    after_validation :normalize_orcid

    # Set up user profile avatars
    mount_uploader :avatar, AvatarUploader, mount_on: :avatar_file_name
    validates_with AvatarValidator

    has_many :trophies
    attr_accessor :update_directory
  end

  # Coerce the ORCID into URL format
  def normalize_orcid
    # Skip normalization if:
    #   1. validation has already flagged the ORCID as invalid
    #   2. the orcid field is blank
    #   3. the orcid is already in its normalized form
    return if self.errors[:orcid].first.present? || self.orcid.blank? || self.orcid.starts_with?('http://orcid.org/')
    bare_orcid = /\d{4}-\d{4}-\d{4}-\d{4}/.match(self.orcid).string
    self.orcid = "http://orcid.org/#{bare_orcid}"
  end

  # Format the json for select2 which requires just an id and a field called text.
  # If we need an alternate format we should probably look at a json template gem
  def as_json(opts = nil)
    { id: user_key, text: display_name ? "#{display_name} (#{user_key})" : user_key }
  end

  # Populate user instance with attributes from remote system (e.g., LDAP)
  # There is no default implementation -- override this in your application
  def populate_attributes
  end

  def email_address
    self.email
  end

  def name
    self.display_name.titleize || raise
  rescue
    self.user_key
  end

  # Redefine this for more intuitive keys in Redis
  def to_param
    # hack because rails doesn't like periods in urls.
    user_key.gsub(/\./, '-dot-')
  end

  def trophy_files
    trophies.map do |t|
      ::GenericFile.load_instance_from_solr(Sufia::Noid.namespaceize(t.generic_file_id))
    end
  end

  # method needed for messaging
  def mailboxer_email(obj=nil)
    nil
  end

  # The basic groups method, override or will fallback to Sufia::Ldap::User
  def groups
    @groups ||= self.group_list ? self.group_list.split(";?;") : []
  end

  def ability
    @ability ||= ::Ability.new(self)
  end

  def get_all_user_activity( since = DateTime.now.to_i - 8640)
    events = self.events.reverse.collect { |event| event if event[:timestamp].to_i > since }.compact
    profile_events = self.profile_events.reverse.collect { |event| event if event[:timestamp].to_i > since }.compact
    events.concat(profile_events).sort { |a, b| b[:timestamp].to_i <=> a[:timestamp].to_i }
  end

  module ClassMethods

    def permitted_attributes
      [:email, :login, :display_name, :address, :admin_area,
        :department, :title, :office, :chat_id, :website, :affiliation,
        :telephone, :avatar, :group_list, :groups_last_update, :facebook_handle,
        :twitter_handle, :googleplus_handle, :linkedin_handle, :remove_avatar,
        :orcid
      ]
    end

    def current
      Thread.current[:user]
    end

    def current=(user)
      Thread.current[:user] = user
    end

    # Override this method if you aren't using email/password
    def audituser
      User.find_by_user_key(audituser_key) || User.create!(Devise.authentication_keys.first => audituser_key, password: Devise.friendly_token[0,20])
    end

    # Override this method if you aren't using email as the userkey
    def audituser_key
      'audituser@example.com'
    end

    # Override this method if you aren't using email/password
    def batchuser
      User.find_by_user_key(batchuser_key) || User.create!(Devise.authentication_keys.first => batchuser_key, password: Devise.friendly_token[0,20])
    end

    # Override this method if you aren't using email as the userkey
    def batchuser_key
      'batchuser@example.com'
    end

    def from_url_component(component)
      User.find_by_user_key(component.gsub(/-dot-/, '.'))
    end
  end
end
