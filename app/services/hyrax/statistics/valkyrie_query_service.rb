# frozen_string_literal: true
module Hyrax
  module Statistics
    class ValkyrieQueryService < QueryService
      # query to find works created during the time range
      # @param [DateTime] start_datetime starting date time for range query
      # @param [DateTime] end_datetime ending date time for range query
      def find_by_date_created(start_datetime, end_datetime = nil)
        return [] if start_datetime.blank? # no date just return nothing
        return super unless non_wings_valkyire?

        Hyrax.query_service.custom_queries.find_by_date_range(start_datetime: start_datetime,
                                                              end_datetime: end_datetime,
                                                              models: relation.allowable_types).to_a
      end

      def find_registered_in_date_range(start_datetime, end_datetime = nil)
        return super unless non_wings_valkyire?
        find_by_date_created(start_datetime, end_datetime) & where_registered.to_a
      end

      def find_public_in_date_range(start_datetime, end_datetime = nil)
        return super unless non_wings_valkyire?
        find_by_date_created(start_datetime, end_datetime) & where_public.to_a
      end

      def relation
        return super unless non_wings_valkyire?
        Hyrax::ValkyrieWorkRelation.new
      end

      private

      def where_access_is(access_level)
        # returns all works where the access level is public
        return super unless non_wings_valkyire?

        Hyrax.custom_queries.find_models_by_access(mode: 'read',
                                                   models: relation.allowable_types,
                                                   group: true,
                                                   agent: access_level)
      end

      def non_wings_valkyire?
        Hyrax.config.use_valkyrie? && (!defined?(Wings) || (defined?(Wings) && Hyrax.config.disable_wings))
      end
    end
  end
end
