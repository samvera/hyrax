# frozen_string_literal: true
module Hyrax
  module Statistics
    class QueryService
      # query to find works created during the time range
      # @param [DateTime] start_datetime starting date time for range query
      # @param [DateTime] end_datetime ending date time for range query
      def find_by_date_created(start_datetime, end_datetime = nil)
        return [] if start_datetime.blank? # no date just return nothing
        if Hyrax.config.use_valkyrie? && !Object.const_defined?("Wings")
          return Hyrax.query_service.custom_queries.find_by_date_range(start_datetime: start_datetime,
                                                                       end_datetime: end_datetime,
                                                                       models: relation.allowable_types).to_a
        end
        relation.where(build_date_query(start_datetime, end_datetime)).to_a
      end

      def find_registered_in_date_range(start_datetime, end_datetime = nil)
        find_by_date_created(start_datetime, end_datetime) & where_registered.to_a
      end

      def find_public_in_date_range(start_datetime, end_datetime = nil)
        find_by_date_created(start_datetime, end_datetime) & where_public.to_a
      end

      def where_public
        where_access_is 'public'
      end

      def where_registered
        where_access_is 'registered'
      end

      def build_date_query(start_datetime, end_datetime)
        start_date_str =  start_datetime.utc.strftime(date_format)
        end_date_str = if end_datetime.blank?
                         "*"
                       else
                         end_datetime.utc.strftime(date_format)
                       end
        "system_create_dtsi:[#{start_date_str} TO #{end_date_str}]"
      end

      delegate :count, to: :relation

      def relation
        return Hyrax::ValkyrieWorkRelation.new if Hyrax.config.use_valkyrie? && !Object.const_defined?("Wings")
        Hyrax::WorkRelation.new
      end

      private

      def where_access_is(access_level)
        # returns all works where the access level is public
        if Hyrax.config.use_valkyrie? && !Object.const_defined?("Wings")
          Hyrax.custom_queries.find_models_by_access(mode: 'read',
                                                     models: relation.allowable_types,
                                                     group: true,
                                                     agent: access_level)
        else
          relation.where Hydra.config.permissions.read.group => access_level
        end
      end

      def date_format
        "%Y-%m-%dT%H:%M:%SZ"
      end
    end
  end
end
