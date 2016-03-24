# Repeats access controls evaluation methods, but checks against a governing "Policy" object (or "Collection" object) that provides inherited access controls.
module Hydra::PolicyAwareAbility
  extend ActiveSupport::Concern
  include Blacklight::AccessControls::Ability
  include Hydra::Ability

  IS_GOVERNED_BY_SOLR_FIELD = "isGovernedBy_ssim".freeze

  # Extends Hydra::Ability.test_edit to try policy controls if object-level controls deny access
  def test_edit(id)
    super || test_edit_from_policy(id)
  end

  # Extends Hydra::Ability.test_read to try policy controls if object-level controls deny access
  def test_read(id)
    super || test_read_from_policy(id)
  end

  # Returns the id of policy object (isGovernedBy_ssim) for the specified object
  # Assumes that the policy object is associated by an isGovernedBy relationship
  # (which is stored as "isGovernedBy_ssim" in object's solr document)
  # Returns nil if no policy associated with the object
  def policy_id_for(object_id)
    policy_id = policy_id_cache[object_id]
    return policy_id if policy_id
    solr_result = ActiveFedora::Base.search_with_conditions({ id: object_id }, fl: governed_by_solr_field).first
    return unless solr_result
    policy_id_cache[object_id] = policy_id = Array(solr_result[governed_by_solr_field]).first
  end

  def governed_by_solr_field
    # TODO the solr key could be derived if we knew the class of the object:
    #   ModsAsset.reflect_on_association(:admin_policy).solr_key
    IS_GOVERNED_BY_SOLR_FIELD
  end

  # Returns the permissions solr document for policy_id
  # The document is stored in an instance variable, so calling this multiple times will only query solr once.
  # To force reload, set @policy_permissions_solr_cache to {}
  def policy_permissions_doc(policy_id)
    @policy_permissions_solr_cache ||= {}
    @policy_permissions_solr_cache[policy_id] ||= get_permissions_solr_response_for_doc_id(policy_id)
  end

  # Tests whether the object's governing policy object grants edit access for the current user
  def test_edit_from_policy(object_id)
    policy_id = policy_id_for(object_id)
    return false if policy_id.nil?
    Rails.logger.debug("[CANCAN] -policy- Does the POLICY #{policy_id} provide EDIT permissions for #{current_user.user_key}?")
    group_intersection = user_groups & edit_groups_from_policy( policy_id )
    result = !group_intersection.empty? || edit_users_from_policy( policy_id ).include?(current_user.user_key)
    Rails.logger.debug("[CANCAN] -policy- decision: #{result}")
    result
  end

  # Tests whether the object's governing policy object grants read access for the current user
  def test_read_from_policy(object_id)
    policy_id = policy_id_for(object_id)
    return false if policy_id.nil?
    Rails.logger.debug("[CANCAN] -policy- Does the POLICY #{policy_id} provide READ permissions for #{current_user.user_key}?")
    group_intersection = user_groups & read_groups_from_policy( policy_id )
    result = !group_intersection.empty? || read_users_from_policy( policy_id ).include?(current_user.user_key)
    Rails.logger.debug("[CANCAN] -policy- decision: #{result}")
    result
  end

  # Returns the list of groups granted edit access by the policy object identified by policy_id
  def edit_groups_from_policy(policy_id)
    policy_permissions = policy_permissions_doc(policy_id)
    edit_group_field = Hydra.config.permissions.inheritable[:edit][:group]
    eg = ((policy_permissions == nil || policy_permissions.fetch(edit_group_field,nil) == nil) ? [] : policy_permissions.fetch(edit_group_field,nil))
    Rails.logger.debug("[CANCAN] -policy- edit_groups: #{eg.inspect}")
    return eg
  end

  # Returns the list of groups granted read access by the policy object identified by policy_id
  # Note: edit implies read, so read_groups is the union of edit and read groups
  def read_groups_from_policy(policy_id)
    policy_permissions = policy_permissions_doc(policy_id)
    read_group_field = Hydra.config.permissions.inheritable[:read][:group]
    rg = edit_groups_from_policy(policy_id) | ((policy_permissions == nil || policy_permissions.fetch(read_group_field,nil) == nil) ? [] : policy_permissions.fetch(read_group_field,nil))
    Rails.logger.debug("[CANCAN] -policy- read_groups: #{rg.inspect}")
    return rg
  end

  # Returns the list of users granted edit access by the policy object identified by policy_id
  def edit_users_from_policy(policy_id)
    policy_permissions = policy_permissions_doc(policy_id)
    edit_user_field = Hydra.config.permissions.inheritable[:edit][:individual]
    eu = ((policy_permissions == nil || policy_permissions.fetch(edit_user_field,nil) == nil) ? [] : policy_permissions.fetch(edit_user_field,nil))
    Rails.logger.debug("[CANCAN] -policy- edit_users: #{eu.inspect}")
    return eu
  end

  # Returns the list of users granted read access by the policy object identified by policy_id
  # Note: edit implies read, so read_users is the union of edit and read users
  def read_users_from_policy(policy_id)
    policy_permissions = policy_permissions_doc(policy_id)
    read_user_field = Hydra.config.permissions.inheritable[:read][:individual]
    ru = edit_users_from_policy(policy_id) | ((policy_permissions == nil || policy_permissions.fetch(read_user_field, nil) == nil) ? [] : policy_permissions.fetch(read_user_field, nil))
    Rails.logger.debug("[CANCAN] -policy- read_users: #{ru.inspect}")
    return ru
  end

  private

  def policy_id_cache
    @policy_id_cache ||= {}
  end

end
