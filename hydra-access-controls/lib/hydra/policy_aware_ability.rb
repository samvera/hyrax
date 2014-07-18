# Repeats access controls evaluation methods, but checks against a governing "Policy" object (or "Collection" object) that provides inherited access controls.
module Hydra::PolicyAwareAbility
  extend ActiveSupport::Concern
  extend Deprecation
  include Hydra::Ability
  
  # Extends Hydra::Ability.test_edit to try policy controls if object-level controls deny access
  def test_edit(pid)
    result = super
    if result 
      return result
    else
      return test_edit_from_policy(pid)
    end
  end
  
  # Extends Hydra::Ability.test_read to try policy controls if object-level controls deny access
  def test_read(pid)
    result = super
    if result 
      return result
    else
      return test_read_from_policy(pid)
    end
  end
  
  # Returns the pid of policy object (is_governed_by) for the specified object
  # Assumes that the policy object is associated by an is_governed_by relationship 
  # (which is stored as "is_governed_by_ssim" in object's solr document)
  # Returns nil if no policy associated with the object
  def policy_pid_for(object_pid)
    policy_pid = policy_pid_cache[object_pid]
    return policy_pid if policy_pid
    solr_result = ActiveFedora::Base.find_with_conditions({:id=>object_pid}, :fl=>ActiveFedora::SolrService.solr_name('is_governed_by', :symbol))
    begin
      policy_pid_cache[object_pid] = policy_pid = value_from_solr_field(solr_result, ActiveFedora::SolrService.solr_name('is_governed_by', :symbol)).first.gsub("info:fedora/", "")
    rescue NoMethodError
    end
    return policy_pid
  end
  
  # Returns the permissions solr document for policy_pid
  # The document is stored in an instance variable, so calling this multiple times will only query solr once.
  # To force reload, set @policy_permissions_solr_cache to {} 
  def policy_permissions_doc(policy_pid)
    @policy_permissions_solr_cache ||= {}
    @policy_permissions_solr_cache[policy_pid] ||= get_permissions_solr_response_for_doc_id(policy_pid)
  end
  
  # Tests whether the object's governing policy object grants edit access for the current user
  def test_edit_from_policy(object_pid)
    policy_pid = policy_pid_for(object_pid)
    if policy_pid.nil?
      return false
    else
      Rails.logger.debug("[CANCAN] -policy- Does the POLICY #{policy_pid} provide EDIT permissions for #{current_user.user_key}?")
      group_intersection = user_groups & edit_groups_from_policy( policy_pid )
      result = !group_intersection.empty? || edit_users_from_policy( policy_pid ).include?(current_user.user_key)
      Rails.logger.debug("[CANCAN] -policy- decision: #{result}")
      return result
    end
  end   
  
  # Tests whether the object's governing policy object grants read access for the current user
  def test_read_from_policy(object_pid)
    policy_pid = policy_pid_for(object_pid)
    if policy_pid.nil?
      return false
    else
      Rails.logger.debug("[CANCAN] -policy- Does the POLICY #{policy_pid} provide READ permissions for #{current_user.user_key}?")
      group_intersection = user_groups & read_groups_from_policy( policy_pid )
      result = !group_intersection.empty? || read_users_from_policy( policy_pid ).include?(current_user.user_key)
      Rails.logger.debug("[CANCAN] -policy- decision: #{result}")
      result
    end
  end 
  
  # Returns the list of groups granted edit access by the policy object identified by policy_pid
  def edit_groups_from_policy(policy_pid)
    policy_permissions = policy_permissions_doc(policy_pid)
    edit_group_field = Hydra.config[:permissions][:inheritable][:edit][:group]
    eg = ((policy_permissions == nil || policy_permissions.fetch(edit_group_field,nil) == nil) ? [] : policy_permissions.fetch(edit_group_field,nil))
    Rails.logger.debug("[CANCAN] -policy- edit_groups: #{eg.inspect}")
    return eg
  end

  # Returns the list of groups granted read access by the policy object identified by policy_pid
  # Note: edit implies read, so read_groups is the union of edit and read groups
  def read_groups_from_policy(policy_pid)
    policy_permissions = policy_permissions_doc(policy_pid)
    read_group_field = Hydra.config[:permissions][:inheritable][:read][:group]
    rg = edit_groups_from_policy(policy_pid) | ((policy_permissions == nil || policy_permissions.fetch(read_group_field,nil) == nil) ? [] : policy_permissions.fetch(read_group_field,nil))
    Rails.logger.debug("[CANCAN] -policy- read_groups: #{rg.inspect}")
    return rg
  end

  def edit_persons_from_policy(policy_pid)
    Deprecation.warn(Hydra::PolicyAwareAbility, "The edit_persons_from_policy method is deprecated and will be removed from Hydra::PolicyAwareAbility in hydra-head 8.0.  Use edit_users_from_policy instead.", caller)
    edit_users_from_policy(policy_pid)
  end

  # Returns the list of users granted edit access by the policy object identified by policy_pid
  def edit_users_from_policy(policy_pid)
    policy_permissions = policy_permissions_doc(policy_pid)
    edit_user_field = Hydra.config[:permissions][:inheritable][:edit][:individual]
    eu = ((policy_permissions == nil || policy_permissions.fetch(edit_user_field,nil) == nil) ? [] : policy_permissions.fetch(edit_user_field,nil))
    Rails.logger.debug("[CANCAN] -policy- edit_users: #{eu.inspect}")
    return eu
  end

  def read_persons_from_policy(policy_pid)
    Deprecation.warn(Hydra::PolicyAwareAbility, "The read_persons_from_policy method is deprecated and will be removed from Hydra::PolicyAwareAbility in hydra-head 8.0.  Use read_users_from_policy instead.", caller)
    read_users_from_policy(policy_pid)
  end

  # Returns the list of users granted read access by the policy object identified by policy_pid
  # Note: edit implies read, so read_users is the union of edit and read users
  def read_users_from_policy(policy_pid)
    policy_permissions = policy_permissions_doc(policy_pid)
    read_user_field = Hydra.config[:permissions][:inheritable][:read][:individual]
    ru = edit_users_from_policy(policy_pid) | ((policy_permissions == nil || policy_permissions.fetch(read_user_field, nil) == nil) ? [] : policy_permissions.fetch(read_user_field, nil))
    Rails.logger.debug("[CANCAN] -policy- read_users: #{ru.inspect}")
    return ru
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

  def policy_pid_cache
    @policy_pid_cache ||= {}
  end

end
