module CurationConcerns::User
  extend ActiveSupport::Concern

  # Copied piecemeal from the pcdm branch of sufia-models. More may yet be necessary.

  included do
    # include Mailboxer::Models::Messageable
    # Connects this user object to Blacklight's Bookmarks and Folders.
    include Blacklight::User
    include Hydra::User

    delegate :can?, :cannot?, to: :ability

    attr_accessor :update_directory
  end

  # Format the json for select2 which requires just an id and a field called text.
  # If we need an alternate format we should probably look at a json template gem
  def as_json(opts = nil)
    { id: user_key, text: display_name ? "#{display_name} (#{user_key})" : user_key }
  end

  # Populate user instance with attributes from remote system (e.g., LDAP)
  # There is no default implementation -- override this in your application
  # def populate_attributes
  # end

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

  # method needed for messaging
  # def mailboxer_email(obj=nil)
  #   nil
  # end

  # The basic groups method, override or will fallback to S ufia::Ldap::User
  # def groups
  #   @groups ||= self.group_list ? self.group_list.split(";?;") : []
  # end

  def ability
    @ability ||= ::Ability.new(self)
  end

  module ClassMethods
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
    # def audituser_key
    #   'audituser@example.com'
    # end

    # Override this method if you aren't using email/password
    # def batchuser
    #   User.find_by_user_key(batchuser_key) || User.create!(Devise.authentication_keys.first => batchuser_key, password: Devise.friendly_token[0,20])
    # end

    # Override this method if you aren't using email as the userkey
    # def batchuser_key
    #   'batchuser@example.com'
    # end

    # def from_url_component(component)
    #   User.find_by_user_key(component.gsub(/-dot-/, '.'))
    # end
  end
end
