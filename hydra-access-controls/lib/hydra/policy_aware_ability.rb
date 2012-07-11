# Repeats access controls evaluation methods, but checks against a governing "Policy" object (or "Collection" object) that provides inherited access controls.
module Hydra::PolicyAwareAbility
  
  # Extends Hydra::Ability.test_edit to try policy controls if object-level controls deny access
  def test_edit(pid, user, session)
    result = super
    if result 
      return result
    else
      return test_edit_from_policy(pid, user, session)
    end
  end
  
  # Extends Hydra::Ability.test_read to try policy controls if object-level controls deny access
  def test_read(pid, user, session)
    result = super
    if result 
      return result
    else
      return test_read_from_policy(pid, user, session)
    end
  end
  
  # Returns the pid of policy object (is_governed_by) for the specified object
  # Assumes that the policy object is associated by an is_governed_by relationship (Whis is stored as "is_governed_by_s" in object's solr document)
  # Returns nil if no policy associated with the object
  def policy_pid_for(object_pid)
    return @policy_pid if @policy_pid
    solr_result = ActiveFedora::Base.find_with_conditions({:id=>object_pid}, :fl=>'is_governed_by_s')
    begin
      @policy_pid = value_from_solr_field(solr_result, 'is_governed_by_s').first.gsub("info:fedora/", "")
    rescue NoMethodError
      @policy_pid = nil
    end
    return @policy_pid
  end
  
  # Returns the permissions solr document for policy_pid
  # The document is stored in an instance variable, so calling this multiple times will only query solr once.
  # To force reload, set @policy_permissions_solr_document to nil
  def policy_permissions_doc(policy_pid)
    return @policy_permissions_solr_document if @policy_permissions_solr_document
    response, @policy_permissions_solr_document = get_permissions_solr_response_for_doc_id(policy_pid)
    @policy_permissions_solr_document
  end
  
  # Tests whether the object's governing policy object grants edit access for the current user
  def test_edit_from_policy(object_pid, user, session)    
    policy_pid = policy_pid_for(object_pid)
    if policy_pid.nil?
      return false
    else
      logger.debug("[CANCAN] -policy- Does the POLICY #{policy_pid} provide EDIT permissions for #{user_key(user)}?")
      group_intersection = user_groups(user, session) & edit_groups_from_policy( policy_pid )
      result = !group_intersection.empty? || edit_persons_from_policy( policy_pid ).include?(user_key(user))
      logger.debug("[CANCAN] -policy- decision: #{result}")
      return result
    end
  end   
  
  # Tests whether the object's governing policy object grants read access for the current user
  def test_read_from_policy(object_pid, user, session)
    policy_pid = policy_pid_for(object_pid)
    if policy_pid.nil?
      return false
    else
      logger.debug("[CANCAN] -policy- Does the POLICY #{policy_pid} provide READ permissions for #{user_key(user)}?")
      group_intersection = user_groups(user, session) & read_groups_from_policy( policy_pid )
      result = !group_intersection.empty? || read_persons_from_policy( policy_pid ).include?(user_key(user))
      logger.debug("[CANCAN] -policy- decision: #{result}")
      result
    end
  end 
  
  # Returns the list of groups granted edit access by the policy object identified by policy_pid
  def edit_groups_from_policy(policy_pid)
    policy_permissions = policy_permissions_doc(policy_pid)
    edit_group_field = Hydra.config[:permissions][:inheritable][:edit][:group]
    eg = ((policy_permissions == nil || policy_permissions.fetch(edit_group_field,nil) == nil) ? [] : policy_permissions.fetch(edit_group_field,nil))
    logger.debug("[CANCAN] -policy- edit_groups: #{eg.inspect}")
    return eg
  end

  # Returns the list of groups granted read access by the policy object identified by policy_pid
  # Note: edit implies read, so read_groups is the union of edit and read groups
  def read_groups_from_policy(policy_pid)
    policy_permissions = policy_permissions_doc(policy_pid)
    read_group_field = Hydra.config[:permissions][:inheritable][:read][:group]
    rg = edit_groups_from_policy(policy_pid) | ((policy_permissions == nil || policy_permissions.fetch(read_group_field,nil) == nil) ? [] : policy_permissions.fetch(read_group_field,nil))
    logger.debug("[CANCAN] -policy- read_groups: #{rg.inspect}")
    return rg
  end

  # Returns the list of individuals granted edit access by the policy object identified by policy_pid
  def edit_persons_from_policy(policy_pid)
    policy_permissions = policy_permissions_doc(policy_pid)
    edit_person_field = Hydra.config[:permissions][:inheritable][:edit][:individual]
    ep = ((policy_permissions == nil || policy_permissions.fetch(edit_person_field,nil) == nil) ? [] : policy_permissions.fetch(edit_person_field,nil))
    logger.debug("[CANCAN] -policy- edit_persons: #{ep.inspect}")
    return ep
  end

  # Returns the list of individuals granted read access by the policy object identified by policy_pid
  # Noate: edit implies read, so read_persons is the union of edit and read persons
  def read_persons_from_policy(policy_pid)
    policy_permissions = policy_permissions_doc(policy_pid)
    read_individual_field = Hydra.config[:permissions][:inheritable][:read][:individual]
    rp = edit_persons_from_policy(policy_pid) | ((policy_permissions == nil || policy_permissions.fetch(read_individual_field,nil) == nil) ? [] : policy_permissions.fetch(read_individual_field,nil))
    logger.debug("[CANCAN] -policy- read_persons: #{rp.inspect}")
    return rp
  end
  
  private
  
  # Grabs the value of field_name from solr_result
  # @example
  #   solr_result = Multiresimage.find_with_conditions({:id=>object_pid}, :fl=>'is_governed_by_s')
  #   value_from_solr_field(solr_result, 'is_governed_by_s')
  #   => ["info:fedora/changeme:2278"]
  def value_from_solr_field(solr_result, field_name)
    field_from_result = solr_result.select {|x| x.has_key?(field_name)}.first
    if field_from_result.nil?
      return nil
    else
      return field_from_result[field_name]
    end
  end
end