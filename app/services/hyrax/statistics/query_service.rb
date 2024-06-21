# frozen_string_literal: true
module Hyrax
  module Statistics
    ##
    # @deprecated for removal in 6.0.0
    class QueryService
      extend Deprecation
      self.deprecation_horizon = 'hyrax version 6.0.0'
      deprecation_deprecate :initialize

      # query to find works created during the time range
      # @param [DateTime] start_datetime starting date time for range query
      # @param [DateTime] end_datetime ending date time for range query
      def find_by_date_created(start_datetime, end_datetime = nil)
        return [] if start_datetime.blank? # no date just return nothing
        relation.where(build_date_query(start_datetime, end_datetime))
      end

      def find_registered_in_date_range(start_datetime, end_datetime = nil)
        find_by_date_created(start_datetime, end_datetime).merge(where_registered)
      end

      def find_public_in_date_range(start_datetime, end_datetime = nil)
        find_by_date_created(start_datetime, end_datetime).merge(where_public)
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
        Hyrax.config.disable_wings ? Hyrax::ValkyrieWorkRelation.new : Hyrax::WorkRelation.new
      end

      private

      def where_access_is(access_level)
        relation.where Hydra.config.permissions.read.group => access_level
      end

      def date_format
        "%Y-%m-%dT%H:%M:%SZ"
      end
    end
  end
end
