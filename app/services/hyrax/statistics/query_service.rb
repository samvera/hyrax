module Hyrax
  module Statistics
    class QueryService
      # query to count works created during the time range
      # @param [DateTime] start_datetime starting date time for range query
      # @param [DateTime] end_datetime ending date time for range query
      def count_by_date_created(start_datetime, end_datetime = nil)
        return 0 if start_datetime.blank? # no date just return nothing
        count([build_date_query(start_datetime, end_datetime)])
      end

      def count_registered_in_date_range(start_datetime, end_datetime = nil)
        return 0 if start_datetime.blank? # no date just return nothing
        count([build_date_query(start_datetime, end_datetime), where_registered])
      end

      def count_public_in_date_range(start_datetime, end_datetime = nil)
        return 0 if start_datetime.blank? # no date just return nothing
        count([build_date_query(start_datetime, end_datetime), where_public])
      end

      def count_public
        count([where_public])
      end

      def count_registered
        count([where_registered])
      end

      def count(clauses = [])
        ActiveFedora::SolrService.count(query(clauses))
      end

      def build_date_query(start_datetime, end_datetime)
        start_date_str =  start_datetime.utc.strftime(date_format)
        end_date_str = if end_datetime.blank?
                         "*"
                       else
                         end_datetime.utc.strftime(date_format)
                       end
        "created_at_dtsi:[#{start_date_str} TO #{end_date_str}]"
      end

      private

        def where_public
          where_access_is 'public'
        end

        def where_registered
          where_access_is 'registered'
        end

        def query(clauses)
          clauses += [search_model_clause]
          clauses.join(' AND ')
        end

        def search_model_clause
          "(_query_:\"{!raw f=internal_resource_ssim}GenericWork\" OR _query_:\"{!raw f=internal_resource_ssim}RareBooks::Atlas\")"
        end

        def where_access_is(access_level)
          "_query_:\"{!field f=read_access_group_ssim}#{access_level}\""
        end

        def date_format
          "%Y-%m-%dT%H:%M:%SZ"
        end
    end
  end
end
