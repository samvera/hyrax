# frozen_string_literal: true
module Hyrax
  module Statistics
    module Works
      class Count
        attr_reader :start_date, :end_date

        # @api public
        # Retrieves the count of works in the system filtered by the start_date and end_date if present
        #
        # @param [Time] start_date Filters the statistics returned by the class to after this date. nil means no filter
        # @param [Time] end_date Filters the statistics returned by the class to before this date. nil means today
        # @return [Hash] A hash with the total files by permission for the system
        # @see #by_permission
        def self.by_permission(start_date: nil, end_date: nil)
          new(start_date, end_date).by_permission
        end

        # @param [Time] start_date Filters the statistics returned by the class to after this date. nil means no filter
        # @param [Time] end_date Filters the statistics returned by the class to before this date. nil means today
        def initialize(start_date = nil, end_date = nil)
          @start_date = start_date
          @end_date = end_date
        end

        # Retrieves the count of works in the system filtered by the start_date and end_date if present
        #
        # @return [Hash] A hash with the total files by permission for the system
        # @option [Number] :total Total number of files without regard to permissions
        # @option [Number] :public Total number of files that have public permissions
        # @option [Number] :registered Total number of files that have registered (logged in) permissions
        # @option [Number] :private Total number of files that have private permissions
        def by_permission
          return by_date_and_permission if start_date

          works_count = {}
          works_count[:total] = query_service.count
          works_count[:public] = query_service.where_public.count
          works_count[:registered] = query_service.where_registered.count
          works_count[:private] = works_count[:total] - (works_count[:registered] + works_count[:public])
          works_count
        end

        private

        def query_service
          @query_service ||= Hyrax::Statistics::ValkyrieQueryService.new
        end

        def by_date_and_permission
          works_count = {}
          works_count[:total] = query_service.find_by_date_created(start_date, end_date).count
          works_count[:public] = query_service.find_public_in_date_range(start_date, end_date).count
          works_count[:registered] = query_service.find_registered_in_date_range(start_date, end_date).count
          works_count[:private] = works_count[:total] - (works_count[:registered] + works_count[:public])
          works_count
        end
      end
    end
  end
end
