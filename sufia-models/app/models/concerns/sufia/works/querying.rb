module Sufia
  module Works
    module Querying
      extend ActiveSupport::Concern

      module ClassMethods
        # query to find generic files created during the time range
        # @param [DateTime] start_datetime starting date time for range query
        # @param [DateTime] end_datetime ending date time for range query
        def find_by_date_created(start_datetime, end_datetime = nil)
          return [] if start_datetime.blank? # no date just return nothing
          start_date_str =  start_datetime.utc.strftime(date_format)
          end_date_str = if end_datetime.blank?
                           "*"
                         else
                           end_datetime.utc.strftime(date_format)
                         end
          where "system_create_dtsi:[#{start_date_str} TO #{end_date_str}]"
        end

        def where_private
          where_access_is 'private'
        end

        def where_public
          where_access_is 'public'
        end

        def where_registered
          where_access_is 'registered'
        end

        def where_access_is(access_level)
          where Solrizer.solr_name('read_access_group', :symbol) => access_level
        end

        def date_format
          "%Y-%m-%dT%H:%M:%SZ"
        end
      end
    end
  end
end
