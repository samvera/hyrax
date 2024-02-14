# frozen_string_literal: true
module Hyrax
  module Dashboard
    class CollectionsSearchBuilder < Hyrax::CollectionSearchBuilder
      include Hyrax::Dashboard::ManagedSearchFilters

      self.solr_access_filters_logic += [:apply_collection_deposit_permissions]
      self.default_processor_chain += [:show_only_managed_collections_for_non_admins]

      # This overrides the models in FilterByType
      def models
        Hyrax::ModelRegistry.admin_set_classes + Hyrax::ModelRegistry.collection_classes
      end

      # adds a filter to exclude collections and admin sets created by the
      # current user if the current user is not an admin.
      # @param [Hash] solr_parameters
      def show_only_managed_collections_for_non_admins(solr_parameters)
        return if current_ability.admin?
        clauses = [
          '-' + ActiveFedora::SolrQueryBuilder.construct_query_for_rel(depositor: current_user_key)
        ]
        Hyrax::ModelRegistry.admin_set_rdf_representations.each do |has_model|
          clauses += ['-' + ActiveFedora::SolrQueryBuilder.construct_query_for_rel(has_model: has_model, creator: current_user_key)]
        end
        solr_parameters[:fq] ||= []
        solr_parameters[:fq] += ["(#{clauses.join(' OR ')})"]
      end

      # Include all admin sets and collections the user has deposit permission for.
      # @return [Array{String}] values are lucence syntax term queries suitable for :fq
      def apply_collection_deposit_permissions(_permission_types, _ability = current_ability)
        collection_ids = collection_ids_for_deposit
        return [] if collection_ids.empty?
        ["{!terms f=id}#{collection_ids.join(',')}"]
      end

      private

      def collection_ids_for_deposit
        Hyrax::Collections::PermissionsService.source_ids_for_deposit(ability: current_ability,
                                                                      exclude_groups: [::Ability.registered_group_name,
                                                                                       ::Ability.public_group_name])
      end
    end
  end
end
