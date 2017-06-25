module Hydra
  module AccessControls
    # A SearchBuilder that applies filters that are expressed within policies.
    # The permissions on the policy are inherited by the objects goverend by the
    # policy.
    class PolicyAwareSearchBuilder < Hydra::AccessControls::SearchBuilder
      # Extends Blacklight::AccessControls::SearchBuilder.apply_gated_discovery
      # to reflect policy-provided access.
      # Appends the result of policy_clauses into the :fq
      # @param [Hash] solr_parameters the current solr parameters, to be
      #               modified herein!
      def apply_gated_discovery(solr_parameters)
        super
        logger.debug("POLICY-aware Solr parameters: #{solr_parameters.inspect}")
      end

      # @return [String,nil] solr query for finding all objects whose policies
      #                      grant discover access to current_user
      def policy_clauses
        policy_ids = policies_with_access
        return nil if policy_ids.empty?
        clauses = policy_ids.map do |id|
          ActiveFedora::SolrQueryBuilder
            .construct_query_for_rel(isGovernedBy: id)
        end
        '(' + clauses.join(' OR '.freeze) + ')'
      end

      # Find all the policies that grant discover/read/edit permissions to this user or any of its groups.
      # Grant access based on user id & group
      def policies_with_access
        #### TODO -- Memoize this and put it in the session?
        user_access_filters = []
        user_access_filters += apply_policy_group_permissions(discovery_permissions)
        user_access_filters += apply_policy_user_permissions(discovery_permissions)
        where = user_access_filters.join(' OR ')
        result = policy_class.search_with_conditions(where,
                                                     fl: 'id',
                                                     rows: policy_class.count)
        logger.debug "get policies: #{result}\n\n"
        result.map { |h| h['id'] }
      end

      # for groups
      # @param [Array{String,#to_sym}] permission_types symbols (or equivalent) from Hydra.config.permissions.inheritable
      def apply_policy_group_permissions(permission_types = discovery_permissions)
        user_access_filters = []
        current_ability.user_groups.each do |group|
          permission_types.each do |type|
            user_access_filters << escape_filter(Hydra.config.permissions.inheritable[type.to_sym].group, group)
          end
        end
        user_access_filters
      end

      # for individual user access
      # @param [Array{String,#to_sym}] permission_types
      def apply_policy_user_permissions(permission_types = discovery_permissions)
        user = current_ability.current_user
        return [] unless user && user.user_key.present?
        permission_types.map do |type|
          escape_filter(Hydra.config.permissions.inheritable[type.to_sym].individual, user.user_key)
        end
      end

      # Override method from blacklight-access_controls
      def discovery_permissions
        @discovery_permissions ||= %w[edit discover read]
      end

      # Returns the Model used for AdminPolicy objects.
      # You can set this by overriding this method or setting
      # Hydra.config[:permissions][:policy_class]
      # Defults to Hydra::AdminPolicy
      def policy_class
        Hydra.config.permissions.policy_class || Hydra::AdminPolicy
      end

      private

      def gated_discovery_filters
        filters = super
        additional_clauses = policy_clauses
        filters << additional_clauses unless additional_clauses.blank?
        filters
      end

      # Find the name of the solr field for this type of permission.
      # e.g. "read_access_group_ssim" or "discover_access_person_ssim".
      # Used by blacklight-access_controls gem.
      def solr_field_for(permission_type, permission_category)
        permissions = Hydra.config.permissions[permission_type.to_sym]
        permission_category == 'group' ? permissions.group : permissions.individual
      end
    end
  end
end
