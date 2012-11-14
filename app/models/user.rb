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

class User < ActiveRecord::Base
  # Adds acts_as_messageable for user mailboxes
  include Mailboxer::Models::Messageable
  # Connects this user object to Blacklight's Bookmarks and Folders.
  include Blacklight::User
  # Workaround to retry LDAP calls a number of times
  include ScholarSphere::Utils

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
  attr_accessible :email, :login, :display_name, :address, :admin_area, :department, :title, :office, :chat_id, :website, :affiliation, :telephone, :avatar, 
  :ldap_available, :ldap_last_update, :group_list, :groups_last_update, :facebook_handle, :twitter_handle, :googleplus_handle

  # Add user avatar (via paperclip library)
  has_attached_file :avatar, :styles => { medium: "300x300>", thumb: "100x100>" }, :default_url => '/assets/missing_:style.png'
  validates :avatar, :attachment_content_type => { :content_type => /^image\/(jpg|jpeg|pjpeg|png|x-png|gif)$/ }, :if => Proc.new { |p| p.avatar.file? }
  validates :avatar, :attachment_size => { :less_than => 2.megabytes }, :if => Proc.new { |p| p.avatar.file? }

  # Pagination hook
  self.per_page = 5

  # This method should display the unique identifier for this user as defined by devise.
  # The unique identifier is what access controls will be enforced against.
  def user_key
    send(Devise.authentication_keys.first)
  end

  def to_s
    login
  end

  def email_address
    return self.email
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

  # method needed for trophies
  def trophies
     trophies = Trophy.where(user_id:self.id)    
    return trophies
  end


  def ldap_exist?
    if (ldap_last_update.blank? || ((Time.now-ldap_last_update) > 24*60*60 ))
      return ldap_exist!
    end
    return ldap_available
  end

  def ldap_exist!
    exist = retry_unless(7.times, lambda { Hydra::LDAP.connection.get_operation_result.code == 53 }) do
      Hydra::LDAP.does_user_exist?(Net::LDAP::Filter.eq('uid', login))
    end rescue false
    if Hydra::LDAP.connection.get_operation_result.code == 0
      logger.debug "exist = #{exist}"
      attrs = {}
      attrs[:ldap_available] = exist
      attrs[:ldap_last_update] = Time.now
      update_attributes(attrs)
      # TODO: Should we retry here if the code is 51-53???
    else
      logger.warn "LDAP error checking exists for #{login}, reason (code: #{Hydra::LDAP.connection.get_operation_result.code}): #{Hydra::LDAP.connection.get_operation_result.message}"
      return false
    end
    return exist
  end

  # Groups that user is a member of
  def groups
    if (groups_last_update.blank? || ((Time.now-groups_last_update) > 24*60*60 ))
      return groups!
    end
    return self.group_list.split(";?;")
  end

  def groups!
    list = self.class.groups(login)

    if Hydra::LDAP.connection.get_operation_result.code == 0
      list.sort!
      logger.debug "groups = #{list}"
      attrs = {}
      attrs[:ldap_na] = false
      attrs[:group_list] = list.join(";?;")
      attrs[:groups_last_update] = Time.now
      update_attributes(attrs)
      # TODO: Should we retry here if the code is 51-53???
    else
      logger.warn "Error getting groups for #{login} reason: #{Hydra::LDAP.connection.get_operation_result.message}"
      return []
    end
    return list
  end

  def self.groups(login)
    groups = retry_unless(7.times, lambda { Hydra::LDAP.connection.get_operation_result.code == 53 }) do
      Hydra::LDAP.groups_for_user(Net::LDAP::Filter.eq('uid', login)) do |result|
        result.first[:psmemberof].select{ |y| y.starts_with? 'cn=umg/' }.map{ |x| x.sub(/^cn=/, '').sub(/,dc=psu,dc=edu/, '') }
      end rescue []
    end
    return groups
  end

  def populate_attributes
    #update exist cache
    exist = ldap_exist!
    logger.warn "No ldapentry exists for #{login}" unless exist
    return unless exist

    begin
      entry = directory_attributes.first
    rescue
      logger.warn "Error getting directory entry: #{Hydra::LDAP.connection.get_operation_result.message}"
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

    # update the group cache also
    groups!
  end

  def directory_attributes(attrs=[])
    self.class.directory_attributes(login, attrs)
  end

  def self.directory_attributes(login, attrs=[])
    attrs = retry_unless(7.times, lambda { Hydra::LDAP.connection.get_operation_result.code == 53 }) do
      Hydra::LDAP.get_user(Net::LDAP::Filter.eq('uid', login), attrs)
    end rescue []
    return attrs
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
