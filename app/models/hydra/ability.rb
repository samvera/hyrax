# this code will move to lib/hydra/access_controls/ability.rb (with the appropriate namespace changes) in Hydra 5.0
# Code for CanCan access to Hydra models
module Hydra::Ability
  include Hydra::AccessControlsEnforcement

  def initialize(user, session=nil)
    user ||= User.new # guest user (not logged in)
    hydra_default_permissions(user, session)
  end

  ## You can override this method if you are using a different AuthZ (such as LDAP)
  def user_groups(user, session)
    return @user_groups if @user_groups
    @user_groups = RoleMapper.roles(user_key(user)) + default_user_groups
    @user_groups << 'registered' unless user.new_record?
    @user_groups
  end

  def default_user_groups
    # # everyone is automatically a member of the group 'public'
    ['public']
  end
  

  def hydra_default_permissions(user, session)
    logger.debug("Usergroups are " + user_groups(user, session).inspect)
    if Deprecation.silence(Hydra::SuperuserAttributes) { user.is_being_superuser?(session) }
      can :manage, :all
    else
      edit_permissions(user, session)
      read_permissions(user, session)
      custom_permissions(user, session)
    end
  end

  def edit_permissions(user, session)
    can :edit, String do |pid|
      test_edit(pid, user, session)
    end 

    can :edit, ActiveFedora::Base do |obj|
      test_edit(obj.pid, user, session)
    end
 
    can :edit, SolrDocument do |obj|
      @permissions_solr_document = obj
      test_edit(obj.id, user, session)
    end       

  end

  def read_permissions(user, session)
    can :read, String do |pid|
      test_read(pid, user, session)
    end

    can :read, ActiveFedora::Base do |obj|
      test_read(obj.pid, user, session)
    end 
    
    can :read, SolrDocument do |obj|
      @permissions_solr_document = obj
      test_read(obj.id, user, session)
    end 
  end


  ## Override custom permissions in your own app to add more permissions beyond what is defined by default.
  def custom_permissions(user, session)
  end
  
  protected

  def permissions_doc(pid)
    return @permissions_solr_document if @permissions_solr_document
    response, @permissions_solr_document = get_permissions_solr_response_for_doc_id(pid)
    @permissions_solr_document
  end


  def test_edit(pid, user, session)
    permissions_doc(pid)
    logger.debug("CANCAN Checking edit permissions for user: #{user}")
    group_intersection = user_groups(user, session) & edit_groups
    result = !group_intersection.empty? || edit_persons.include?(user_key(user))
    logger.debug("CANCAN decision: #{result}")
    result
  end   
  
  def test_read(pid, user, session)
    permissions_doc(pid)
    logger.debug("CANCAN Checking edit permissions for user: #{user}")
    group_intersection = user_groups(user, session) & read_groups
    result = !group_intersection.empty? || read_persons.include?(user_key(user))
    logger.debug("CANCAN decision: #{result}")
    result
  end 
  
  def edit_groups
    edit_group_field = Hydra.config[:permissions][:edit][:group]
    eg = ((@permissions_solr_document == nil || @permissions_solr_document.fetch(edit_group_field,nil) == nil) ? [] : @permissions_solr_document.fetch(edit_group_field,nil))
    logger.debug("edit_groups: #{eg.inspect}")
    return eg
  end

  # edit implies read, so read_groups is the union of edit and read groups
  def read_groups
    read_group_field = Hydra.config[:permissions][:read][:group]
    rg = edit_groups | ((@permissions_solr_document == nil || @permissions_solr_document.fetch(read_group_field,nil) == nil) ? [] : @permissions_solr_document.fetch(read_group_field,nil))
    logger.debug("read_groups: #{rg.inspect}")
    return rg
  end

  def edit_persons
    edit_person_field = Hydra.config[:permissions][:edit][:individual]
    ep = ((@permissions_solr_document == nil || @permissions_solr_document.fetch(edit_person_field,nil) == nil) ? [] : @permissions_solr_document.fetch(edit_person_field,nil))
    logger.debug("edit_persons: #{ep.inspect}")
    return ep
  end

  # edit implies read, so read_persons is the union of edit and read persons
  def read_persons
    read_individual_field = Hydra.config[:permissions][:read][:individual]
    rp = edit_persons | ((@permissions_solr_document == nil || @permissions_solr_document.fetch(read_individual_field,nil) == nil) ? [] : @permissions_solr_document.fetch(read_individual_field,nil))
    logger.debug("read_persons: #{rp.inspect}")
    return rp
  end

  
  # get the currently configured user identifier.  Can be overridden to return whatever (ie. login, email, etc)
  # defaults to using whatever you have set as the Devise authentication_key
  def user_key(user)
    user.send(Devise.authentication_keys.first)
  end


end
