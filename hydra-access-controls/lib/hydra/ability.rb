# Code for [CANCAN] access to Hydra models
require 'cancan'
module Hydra::Ability
  extend ActiveSupport::Concern
  
  # once you include Hydra::Ability you can add custom permission methods by appending to ability_logic like so:
  #
  # self.ability_logic +=[:setup_my_permissions]
  
  included do
    include CanCan::Ability
    include Hydra::PermissionsQuery
    include Blacklight::SolrHelper
    class_attribute :ability_logic
    self.ability_logic = [:create_permissions, :edit_permissions, :read_permissions, :custom_permissions]
  end

  def self.user_class
    Hydra.config[:user_model] ?  Hydra.config[:user_model].constantize : ::User
  end

  attr_reader :current_user, :session

  def initialize(user, session=nil)
    @current_user = user || Hydra::Ability.user_class.new # guest user (not logged in)
    @user = @current_user # just in case someone was using this in an override. Just don't.
    @session = session
    hydra_default_permissions()
  end

  ## You can override this method if you are using a different AuthZ (such as LDAP)
  def user_groups
    return @user_groups if @user_groups
    
    @user_groups = default_user_groups
    @user_groups |= current_user.groups if current_user and current_user.respond_to? :groups
    @user_groups |= ['registered'] unless current_user.new_record?
    @user_groups
  end

  def default_user_groups
    # # everyone is automatically a member of the group 'public'
    ['public']
  end
  

  def hydra_default_permissions
    logger.debug("Usergroups are " + user_groups.inspect)
    self.ability_logic.each do |method|
      send(method)
    end
  end

  def create_permissions
    can :create, :all if user_groups.include? 'registered'
  end

  def edit_permissions
    can [:edit, :update, :destroy], String do |pid|
      test_edit(pid)
    end 

    can [:edit, :update, :destroy], ActiveFedora::Base do |obj|
      test_edit(obj.pid)
    end
 
    can :edit, SolrDocument do |obj|
      @permission_doc_cache[obj.id] = obj
      test_edit(obj.id)
    end       
  end

  def read_permissions
    can :read, String do |pid|
      test_read(pid)
    end

    can :read, ActiveFedora::Base do |obj|
      test_read(obj.pid)
    end 
    
    can :read, SolrDocument do |obj|
      @permission_doc_cache[obj.id] = obj
      test_read(obj.id)
    end 
  end


  ## Override custom permissions in your own app to add more permissions beyond what is defined by default.
  def custom_permissions
  end
  
  protected

  def test_edit(pid)
    permissions_doc(pid)
    logger.debug("[CANCAN] Checking edit permissions for user: #{current_user.user_key} with groups: #{user_groups.inspect}")
    group_intersection = user_groups & edit_groups(pid)
    result = !group_intersection.empty? || edit_persons(pid).include?(current_user.user_key)
    logger.debug("[CANCAN] decision: #{result}")
    result
  end   
  
  def test_read(pid)
    permissions_doc(pid)
    logger.debug("[CANCAN] Checking read permissions for user: #{current_user.user_key} with groups: #{user_groups.inspect}")
    group_intersection = user_groups & read_groups(pid)
    result = !group_intersection.empty? || read_persons(pid).include?(current_user.user_key)
    logger.debug("[CANCAN] decision: #{result}")
    result
  end 
  
  def edit_groups(pid)
    edit_group_field = Hydra.config[:permissions][:edit][:group]
    doc = permissions_doc(pid)
    eg = ((doc == nil || doc.fetch(edit_group_field,nil) == nil) ? [] : doc.fetch(edit_group_field,nil))
    logger.debug("[CANCAN] edit_groups: #{eg.inspect}")
    return eg
  end

  # edit implies read, so read_groups is the union of edit and read groups
  def read_groups(pid)
    read_group_field = Hydra.config[:permissions][:read][:group]
    doc = permissions_doc(pid)
    rg = edit_groups(pid) | ((doc == nil || doc.fetch(read_group_field,nil) == nil) ? [] : doc.fetch(read_group_field,nil))
    logger.debug("[CANCAN] read_groups: #{rg.inspect}")
    return rg
  end

  def edit_persons(pid)
    edit_person_field = Hydra.config[:permissions][:edit][:individual]
    doc = permissions_doc(pid)
    ep = ((doc == nil || doc.fetch(edit_person_field,nil) == nil) ? [] : doc.fetch(edit_person_field,nil))
    logger.debug("[CANCAN] edit_persons: #{ep.inspect}")
    return ep
  end

  # edit implies read, so read_persons is the union of edit and read persons
  def read_persons(pid)
    read_individual_field = Hydra.config[:permissions][:read][:individual]
    doc = permissions_doc(pid)
    rp = edit_persons(pid) | ((doc == nil || doc.fetch(read_individual_field,nil) == nil) ? [] : doc.fetch(read_individual_field,nil))
    logger.debug("[CANCAN] read_persons: #{rp.inspect}")
    return rp
  end

end
