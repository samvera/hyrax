# frozen_string_literal: true
module Hyrax
  module Dashboard
    module ManagedSearchFilters
      extend ActiveSupport::Concern

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
    end
  end
end
