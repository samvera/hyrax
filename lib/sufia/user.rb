# Copyright © 2012 The Pennsylvania State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Sufia::User
  extend ActiveSupport::Concern

  included do
    # Adds acts_as_messageable for user mailboxes
    include Mailboxer::Models::Messageable
    # Connects this user object to Blacklight's Bookmarks and Folders.
    include Blacklight::User
    include Hydra::User

    delegate :can?, :cannot?, :to => :ability

    # set this up as a messageable object
    acts_as_messageable

    # Users should be able to follow things
    acts_as_follower
    # Users should be followable
    acts_as_followable

    # Setup accessible (or protected) attributes for your model
    attr_accessible :email, :login, :display_name, :address, :admin_area, :department, :title, :office, :chat_id, :website, :affiliation, :telephone, :avatar, 
    :group_list, :groups_last_update, :facebook_handle, :twitter_handle, :googleplus_handle

    # Add user avatar (via paperclip library)
    has_attached_file :avatar, :styles => { medium: "300x300>", thumb: "100x100>" }, :default_url => '/assets/missing_:style.png'
    validates :avatar, :attachment_content_type => { :content_type => /^image\/(jpg|jpeg|pjpeg|png|x-png|gif)$/ }, :if => Proc.new { |p| p.avatar.file? }
    validates :avatar, :attachment_size => { :less_than => 2.megabytes }, :if => Proc.new { |p| p.avatar.file? }

  end

  # This method should display the unique identifier for this user as defined by devise.
  # The unique identifier is what access controls will be enforced against.
  def user_key
    send(Devise.authentication_keys.first)
  end

  def to_s
    user_key
  end

  def email_address
    return self.email
  end

  def name
    return self.display_name.titleize || self.user_key rescue self.user_key
  end

  # Redefine this for more intuitive keys in Redis
  def to_param
    user_key
  end

  # method needed for trophies
  def trophies
     trophies = Trophy.where(user_id:self.id)
    return trophies
  end
  
  #method to get the trophy ids without the namespace included
  def trophy_ids
    trophies=[]
    trophies.each do |t|
      @trophies << GenericFile.find("#{Sufia::Engine.config.id_namespace}:#{t.generic_file_id}")
 
    end
    return trophies
  end

  # method needed for messaging
  def mailboxer_email(obj=nil)
    return nil
  end

  # The basic groups method, override or will fallback to Sufia::Ldap::User 
  def groups
    return self.group_list ? self.group_list.split(";?;") : []
  end

  def ability
    @ability ||= Ability.new(self)
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
  end

end
