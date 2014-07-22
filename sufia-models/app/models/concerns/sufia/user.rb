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

    mount_uploader :avatar, AvatarUploader, mount_on: :avatar_file_name
    validates_with AvatarValidator
    has_many :trophies
    attr_accessor :update_directory
  end

  # Format the json for select2 which requires just an id and a field called text.
  # If we need an alternate format we should probably look at a json template gem
  def as_json(opts = nil)
    {id: user_key, text: display_name ? "#{display_name} (#{user_key})" : user_key}
  end

  def email_address
    return self.email
  end

  def name
    return self.display_name.titleize || self.user_key rescue self.user_key
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
    return nil
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
        :twitter_handle, :googleplus_handle, :linkedin_handle, :remove_avatar]
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
