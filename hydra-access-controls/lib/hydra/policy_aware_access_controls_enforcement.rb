# Repeats access controls evaluation methods, but checks against a governing "Policy" object (or "Collection" object) that provides inherited access controls.
module Hydra::PolicyAwareAccessControlsEnforcement
  extend Deprecation

  # Extends Hydra::AccessControlsEnforcement.apply_gated_discovery to reflect policy-provided access
  # appends the result of policy_clauses into the :fq
  # @param solr_parameters the current solr parameters
  # @param user_parameters the current user-subitted parameters
  def apply_gated_discovery(solr_parameters, user_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << gated_discovery_filters.join(" OR ")
    logger.debug("POLICY-aware Solr parameters: #{ solr_parameters.inspect }")
  end

  # returns solr query for finding all objects whose policies grant discover access to current_user
  def policy_clauses
    policy_pids = policies_with_access
    return nil if policy_pids.empty?
    '(' + policy_pids.map {|pid| ActiveFedora::SolrService.construct_query_for_rel(is_governed_by: "info:fedora/#{pid}")}.join(' OR ') + ')'
  end

  # find all the policies that grant discover/read/edit permissions to this user or any of its groups
  def policies_with_access
    #### TODO -- Memoize this and put it in the session?
    user_access_filters = []
    # Grant access based on user id & group
    user_access_filters += apply_policy_group_permissions(discovery_permissions)
    user_access_filters += apply_policy_user_permissions(discovery_permissions)
    result = policy_class.find_with_conditions( user_access_filters.join(" OR "), :fl => "id", :rows => policy_class.count )
    logger.debug "get policies: #{result}\n\n"
    result.map {|h| h['id']}
  end

  def apply_policy_role_permissions(permission_types = discovery_permissions)
    Deprecation.warn(Hydra::PolicyAwareAccessControlsEnforcement, "The method apply_policy_role_permissions is deprecated and will be removed from Hydra::PolicyAwareAccessControlsEnforcement in hydra-head 8.0.  Use apply_policy_group_permissions instead.", caller)
    apply_policy_group_permissions(permission_types)
  end

  def apply_policy_group_permissions(permission_types = discovery_permissions)
      # for groups
      user_access_filters = []
      current_ability.user_groups.each_with_index do |group, i|
        permission_types.each do |type|
          user_access_filters << escape_filter(Hydra.config.permissions.inheritable[type.to_sym].group, group)
        end
      end
      user_access_filters
  end

  def apply_policy_individual_permissions(permission_types = discovery_permissions)
    Deprecation.warn(Hydra::PolicyAwareAccessControlsEnforcement, "The method apply_policy_individual_permissions is deprecated and will be removed from Hydra::PolicyAwareAccessControlsEnforcement in hydra-head 8.0.  Use apply_policy_user_permissions instead.", caller)
    apply_policy_user_permissions(permission_types)
  end

  def apply_policy_user_permissions(permission_types = discovery_permissions)
    # for individual user access
    user_access_filters = []
    if current_user
      permission_types.each do |type|
        user_access_filters << escape_filter(Hydra.config.permissions.inheritable[type.to_sym].individual, current_user.user_key)
      end
    end
    user_access_filters
  end

  # Returns the Model used for AdminPolicy objects.
  # You can set this by overriding this method or setting Hydra.config[:permissions][:policy_class]
  # Defults to Hydra::AdminPolicy
  def policy_class
    Hydra.config.permissions.policy_class || Hydra::AdminPolicy
  end

  protected

  def gated_discovery_filters
    filters = super
    additional_clauses = policy_clauses
    unless additional_clauses.blank?
      filters << additional_clauses
    end
    filters
  end

end
