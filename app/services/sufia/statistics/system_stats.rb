module Sufia
  module Statistics
    # A class that retrieves system level statistics about the system
    # TODO: this class could be refactored into several classes.
    #
    # @attr_reader [Integer] limit      limits the results returned from top_depositors and top_formats
    #                             Default is 5, maximum is 20, minimum is 5
    # @attr_reader [Time] start_date Filters the statistics returned by the class to after the start date
    #                             nil means no filter
    # @attr_reader [Time] end_date   Filters the statistics returned by the class to before end date
    #                             nil means today
    class SystemStats
      attr_reader :limit, :start_date, :end_date

      # @param [Fixnum] limit_records limits the results returned from top_depositors and top_formats. Maximum is 20, minimum is 5
      # @param [Time] start_date Filters the statistics returned by the class to after this date. nil means no filter
      # @param [Time] end_date Filters the statistics returned by the class to before this date. nil means today
      def initialize(limit_records = 5, start_date = nil, end_date = nil)
        @limit = validate_limit(limit_records)
        @start_date = start_date
        @end_date = end_date
      end

      # returns a list (of size limit) of system users (depositors) that have the most deposits in the system
      # @return [Hash] a hash with the user name as the key and the number of deposits as the value
      #    { 'cam156' => 25, 'hjc14' => 24 ... }
      def top_depositors
        top_data(depositor_field, limit)
      end

      delegate :depositor_field, to: DepositSearchBuilder

      # returns a list (of size limit) of file formats (mime_types) that have the most files in the system
      # @return [Hash] a hash with the file format as the key and the number of files as the value
      #    { 'png' => 25, 'pdf' => 24 ... }
      def top_formats
        format_key = Solrizer.solr_name('file_format', Solrizer::Descriptor.new(:string, :indexed, :multivalued))
        top_data(format_key, limit)
      end

      # returns [Array<user>] a list (of size limit) of users most recently registered with the system
      #
      def recent_users
        # no dates return the top few based on limit
        return ::User.order('created_at DESC').limit(limit) if start_date.blank?

        ::User.recent_users start_date, end_date
      end

      # returns [Number] the number of currently registered users
      #
      def users_count
        ::User.count
      end

      private

        def validate_limit(count)
          if count.blank? || count < 5
            5
          elsif count > 20
            20
          else
            count
          end
        end

        def solr_connection
          ActiveFedora::SolrService.instance.conn
        end

        def top_data(key, limit)
          # Grab JSON response (looks like {"terms": {"depositor_tesim": {"mjg36": 3}}} for depositor)
          json = solr_connection.get 'terms', params: { 'terms.fl' => key,
                                                        'terms.sort' => 'count',
                                                        'terms.limit' => limit,
                                                        wt: 'json',
                                                        'json.nl' => 'map',
                                                        omitHeader: 'true' }
          unless json
            Rails.logger.error "Unable to reach TermsComponent via Solr connection. Is it enabled in your solr config?"
            return []
          end

          json['terms'][key]
        end
    end
  end
end
