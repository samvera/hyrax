# Code for [CANCAN] access to Hydra models
require 'cancan'
module Hydra::Ability
  extend ActiveSupport::Concern
  
  # once you include Hydra::Ability you can add custom permission methods by appending to ability_logic like so:
  #
  # self.ability_logic +=[:setup_my_permissions]
  
  included do
    include CanCan::Ability
    include Hydra::AccessControlsEnforcement
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
  def user_groups(deprecated_user=nil, deprecated_session=nil)
    ActiveSupport::Deprecation.warn("No need to pass user or session to user_groups, use the instance_variables", caller()) if deprecated_user || deprecated_session

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
  

  # Requires no arguments, but accepts 2 arguments for backwards compatibility
  def hydra_default_permissions(deprecated_user=nil, deprecated_session=nil)
    ActiveSupport::Deprecation.warn("No need to pass user or session to hydra_default_permissions, use the instance_variables", caller()) if deprecated_user || deprecated_session
    logger.debug("Usergroups are " + user_groups.inspect)
    self.ability_logic.each do |method|
      send(method)
    end
  end

  def create_permissions(deprecated_user=nil, deprecated_session=nil)
    ActiveSupport::Deprecation.warn("No need to pass user or session to create_permissions, use the instance_variables", caller()) if deprecated_user || deprecated_session
    can :create, :all if user_groups.include? 'registered'
  end

  def edit_permissions(deprecated_user=nil, deprecated_session=nil)
    ActiveSupport::Deprecation.warn("No need to pass user or session to edit_permissions, use the instance_variables", caller()) if deprecated_user || deprecated_session
    can [:edit, :update, :destroy], String do |pid|
      test_edit(pid)
    end 

    can [:edit, :update, :destroy], ActiveFedora::Base do |obj|
      test_edit(obj.pid)
    end
 
    can :edit, SolrDocument do |obj|
      @permissions_solr_document = obj
      test_edit(obj.id)
    end       
  end

  def read_permissions(deprecated_user=nil, deprecated_session=nil)
    ActiveSupport::Deprecation.warn("No need to pass user or session to read_permissions, use the instance_variables", caller()) if deprecated_user || deprecated_session
    can :read, String do |pid|
      test_read(pid)
    end

    can :read, ActiveFedora::Base do |obj|
      test_read(obj.pid)
    end 
    
    can :read, SolrDocument do |obj|
      @permissions_solr_document = obj
      test_read(obj.id)
    end 
  end


  ## Override custom permissions in your own app to add more permissions beyond what is defined by default.
  def custom_permissions(deprecated_user=nil, deprecated_session=nil)
    ActiveSupport::Deprecation.warn("No need to pass user or session to custom_permissions, use the instance_variables", caller()) if deprecated_user || deprecated_session
  end
  
  protected

  def permissions_doc(pid)
    return @permissions_solr_document if @permissions_solr_document
    response, @permissions_solr_document = get_permissions_solr_response_for_doc_id(pid)
    @permissions_solr_document
  end


  def test_edit(pid, deprecated_user=nil, deprecated_session=nil)
    ActiveSupport::Deprecation.warn("No need to pass user or session to test_edit, use the instance_variables", caller()) if deprecated_user || deprecated_session
    permissions_doc(pid)
    logger.debug("[CANCAN] Checking edit permissions for user: #{current_user.user_key} with groups: #{user_groups.inspect}")
    group_intersection = user_groups & edit_groups
    result = !group_intersection.empty? || edit_persons.include?(current_user.user_key)
    logger.debug("[CANCAN] decision: #{result}")
    result
  end   
  
  def test_read(pid, deprecated_user=nil, deprecated_session=nil)
    ActiveSupport::Deprecation.warn("No need to pass user or session to test_read, use the instance_variables", caller()) if deprecated_user || deprecated_session
    permissions_doc(pid)
    logger.debug("[CANCAN] Checking read permissions for user: #{current_user.user_key} with groups: #{user_groups.inspect}")
    group_intersection = user_groups & read_groups
    result = !group_intersection.empty? || read_persons.include?(current_user.user_key)
    logger.debug("[CANCAN] decision: #{result}")
    result
  end 
  
  def edit_groups
    edit_group_field = Hydra.config[:permissions][:edit][:group]
    eg = ((@permissions_solr_document == nil || @permissions_solr_document.fetch(edit_group_field,nil) == nil) ? [] : @permissions_solr_document.fetch(edit_group_field,nil))
    logger.debug("[CANCAN] edit_groups: #{eg.inspect}")
    return eg
  end

  # edit implies read, so read_groups is the union of edit and read groups
  def read_groups
    read_group_field = Hydra.config[:permissions][:read][:group]
    rg = edit_groups | ((@permissions_solr_document == nil || @permissions_solr_document.fetch(read_group_field,nil) == nil) ? [] : @permissions_solr_document.fetch(read_group_field,nil))
    logger.debug("[CANCAN] read_groups: #{rg.inspect}")
    return rg
  end

  def edit_persons
    edit_person_field = Hydra.config[:permissions][:edit][:individual]
    ep = ((@permissions_solr_document == nil || @permissions_solr_document.fetch(edit_person_field,nil) == nil) ? [] : @permissions_solr_document.fetch(edit_person_field,nil))
    logger.debug("[CANCAN] edit_persons: #{ep.inspect}")
    return ep
  end

  # edit implies read, so read_persons is the union of edit and read persons
  def read_persons
    read_individual_field = Hydra.config[:permissions][:read][:individual]
    rp = edit_persons | ((@permissions_solr_document == nil || @permissions_solr_document.fetch(read_individual_field,nil) == nil) ? [] : @permissions_solr_document.fetch(read_individual_field,nil))
    logger.debug("[CANCAN] read_persons: #{rp.inspect}")
    return rp
  end

  
  # get the currently configured user identifier.  Can be overridden to return whatever (ie. login, email, etc)
  # defaults to using whatever you have set as the Devise authentication_key
  def user_key(user)
    ActiveSupport::Deprecation.warn("Ability#user_key is deprecated, call user.user_key instead", caller(1))
    user.send(Devise.authentication_keys.first)
  end


end
