# Repeats access controls evaluation methods, but checks against a governing "Policy" object (or "Collection" object) that provides inherited access controls.
module Hydra::PolicyAwareAccessControlsEnforcement
  
  # Extends Hydra::AccessControlsEnforcement.apply_gated_discovery to reflect policy-provided access
  # appends the result of policy_clauses into the :fq
  def apply_gated_discovery(solr_parameters, user_parameters)
    super
    additional_clauses = policy_clauses
    unless additional_clauses.nil? || additional_clauses.empty?
      solr_parameters[:fq].first << " OR " + policy_clauses
      logger.debug("POLICY-aware Solr parameters: #{ solr_parameters.inspect }")
    end
  end
  
  # returns solr query for finding all objects whose policies grant discover access to current_user
  def policy_clauses 
    policy_pids = policies_with_access
    return nil if policy_pids.empty?
    '(' + policy_pids.map {|pid| "is_governed_by_s:info\\:fedora/#{pid.gsub(/:/, '\\\\:')}"}.join(' OR ') + ')'
  end
  
  
  # find all the policies that grant discover/read/edit permissions to this user or any of it's groups
  def policies_with_access
    #### TODO -- Memoize this and put it in the session?
    return [] unless current_user
    user_access_filters = []
    # Grant access based on user id & role
    unless current_user.nil?
      user_access_filters += apply_policy_role_permissions(discovery_permissions)
      user_access_filters += apply_policy_individual_permissions(discovery_permissions)
    end
    result = policy_class.find_with_conditions( user_access_filters.join(" OR "), :fl => "id" )
    logger.debug "get policies: #{result}\n\n"
    result.map {|h| h['id']}
  end
  
  
  def apply_policy_role_permissions(permission_types)
      # for roles
      user_access_filters = []
      ::RoleMapper.roles(user_key).each_with_index do |role, i|
        discovery_permissions.each do |type|
          user_access_filters << "inheritable_#{type}_access_group_t:#{role}"
        end
      end
      user_access_filters
  end

  def apply_policy_individual_permissions(permission_types)
      # for individual person access
      user_access_filters = []
      discovery_permissions.each do |type|
        user_access_filters << "inheritable_#{type}_access_person_t:#{user_key}"        
      end
      user_access_filters
  end
  
  # Returns the Model used for AdminPolicy objects.
  # You can set this by overriding this method or setting Hydra.config[:permissions][:policy_class]
  # Defults to Hydra::AdminPolicy
  def policy_class
    if Hydra.config[:permissions][:policy_class].nil?
      return Hydra::AdminPolicy
    else
      return Hydra.config[:permissions][:policy_class]
    end
  end
  
end