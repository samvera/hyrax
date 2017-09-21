module Hyrax
  module Dashboard
    class CollectionsSearchBuilder < Hyrax::CollectionSearchBuilder
      self.solr_access_filters_logic += [:apply_admin_set_deposit_permissions]
      self.default_processor_chain += [:show_only_managed_collections_for_non_admins]

      # This overrides the models in FilterByType
      def models
        [::AdminSet, ::Collection]
      end

      # adds a filter to exclude collections and admin sets created by the
      # current user if the current user is not an admin.
      # @param [Hash] solr_parameters
      def show_only_managed_collections_for_non_admins(solr_parameters)
        return if current_ability.admin?
        clauses = [
          '-' + ActiveFedora::SolrQueryBuilder.construct_query_for_rel(depositor: current_user_key),
          '-' + ActiveFedora::SolrQueryBuilder.construct_query_for_rel(has_model: ::AdminSet.to_s, creator: current_user_key)
        ]
        solr_parameters[:fq] ||= []
        solr_parameters[:fq] += ["(#{clauses.join(' OR ')})"]
      end

      # This includes collection/admin the user can manage and view.
      def discovery_permissions
        @discovery_permissions ||= %w[edit read]
      end

      # Override to exclude 'public' and 'registered' groups from read access.
      def apply_group_permissions(permission_types, ability = current_ability)
        groups = ability.user_groups
        return [] if groups.empty?
        permission_types.map do |type|
          field = solr_field_for(type, 'group')
          user_groups = type == 'read' ? groups - ['public', 'registered'] : groups
          next if user_groups.empty?
          "({!terms f=#{field}}#{user_groups.join(',')})" # parens required to properly OR the clauses together.
        end
      end

      # Include all admin sets the user has deposit permission for.
      # @return [Array{String}] values are lucence syntax term queries suitable for :fq
      def apply_admin_set_deposit_permissions(_permission_types, _ability = current_ability)
        collection_ids = source_ids_for_deposit
        return [] if collection_ids.empty?
        ["{!terms f=id}#{collection_ids.join(',')}"]
      end

      delegate :source_ids_for_deposit, to: :current_ability
      private :source_ids_for_deposit
    end
  end
end
