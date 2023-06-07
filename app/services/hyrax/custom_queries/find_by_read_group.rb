# frozen_string_literal: true
module Hyrax
  module CustomQueries
    ##
    # @see https://github.com/samvera/valkyrie/wiki/Queries#custom-queries
    class FindByReadGroup
      def self.queries
        [:find_by_read_group]
      end

      def initialize(query_service:)
        @query_service = query_service
      end

      attr_reader :query_service
      delegate :resource_factory, to: :query_service
      delegate :orm_class, to: :resource_factory

      ##
      # @note this is an unoptimized default implementation of this custom
      #   query. it's Hyrax's policy to provide such implementations of custom
      #   queries in use for cross-compatibility of Valkyrie query services.
      #   it's advisable to provide an optimized query for the specific adapter.
      #
      # @param model [Class]
      # @param ids [Enumerable<#to_s>, Symbol]
      #
      # @return [Enumerable<Valkyrie::ID>]
      def find_by_read_group(models, access_level)
        internal_array = "{\"permissions\": [{\"mode\": \"read\", \"agent\": \"group/#{access_level}\"}]}"
        query_service.run_query(find_models_by_access_query, internal_array, models.allowable_types)

        work_ids = orm_class.find_by_sql(([get_all_model_ids_query(models.allowable_types)])).lazy.map(&:id)
        acs = work_ids.map { |id| find_access_control_for(id: id) }
        matched_acs = acs.select { |ac| ac.permissions.count { |p| p.mode == :read && p.agent == "group/#{access_level}" }.nonzero? }
        works_with_access = matched_acs.map do |ac|
          query_service.find_by(id: ac.access_to)
        end
        all_works = models.allowable_types.map { |model| query_service.find_all_of_model(model: model) }.lazy.flat_map(&:lazy)
        works_with_access = all_works.select { |work| work.read_groups.include?(access_level) }
      end

      def find_models_by_access_query
        <<-SQL
          SELECT * FROM orm_resources
          WHERE id IN (
            SELECT uuid(metadata::json#>'{access_to,0}'->>'id') FROM orm_resources
            WHERE metadata @> ?
          ) AND internal_resource IN (?);
        SQL
      end





      def get_all_model_ids_query(models)
        <<-SQL
          SELECT id FROM orm_resources WHERE internal_resource IN ('#{models.join("', '")}');
        SQL
      end

      def find_access_control_for(id:)
        get_inverse_reference_for(id: id, property: :access_to)
            .find { |r| r.is_a?(Hyrax::AccessControl) } ||
            raise(Valkyrie::Persistence::ObjectNotFoundError)
      rescue ArgumentError # some adapters raise ArgumentError for missing resources
        raise(Valkyrie::Persistence::ObjectNotFoundError)
      end

      def get_inverse_reference_for(id:, property: :access_to)
        raise ArgumentError, "Provide id" unless id
        internal_array = "{\"#{property}\": [{\"id\": \"#{id}\"}]}"
        query_service.run_query(get_inverse_references_query, internal_array)
      end

      def get_inverse_references_query
        <<-SQL
          SELECT * FROM orm_resources WHERE metadata @> ?
        SQL
      end
    end
  end
end
