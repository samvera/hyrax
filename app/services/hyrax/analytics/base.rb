module Hyrax
  module Analytics
    # @abstract Base class for Analytics services that support statistics needs in Hyrax.
    # Implementing subclasses must define `#connection` `#remote_statistics` and `#to_graph`
    class Base
      # Establish connection with the analytics service
      def self.connection
        raise NotImplementedError, "#{self.class}#connection is unimplemented."
      end

      # Query the number of pageviews for a given time period against the specified object
      # @param [DateTime] _start_date
      # @param [ActiveFedora::Base] _object
      #
      # @return [OpenStruct] - Should contain attributes for date and pageviews
      # Example: <OpenStruct date="20180201", pageviews="1">
      def self.pageviews(_start_date, _object)
        raise NotImplementedError, "#{self.class}#pageviews is unimplemented."
      end

      # Query the number of downloads for a given time period against the specified object
      # @param [DateTime] _start_date
      # @param [FileSet] _object
      #
      # @return [OpenStruct] - Should contain attributes for date and totalEvents. Other attributes currently aren't
      # used.
      # Example: <OpenStruct eventCategory="Files", eventAction="Downloaded", eventLabel="j67313767", date="20180212", totalEvents="1">
      def self.downloads(_start_date, _object)
        raise NotImplementedError, "#{self.class}#downloads is unimplemented."
      end

      # Query the number of unique visitors for a given time period
      # @param [DateTime] _start_date
      #
      # @return [OpenStruct] - Should contain attributes for date and uniqueVisitors
      # used.
      # Example: <OpenStruct date="20180212", uniqueVisitors="1">
      def self.unique_visitors(_start_date)
        raise NotImplementedError, "#{self.class}#unique_visitors is unimplemented."
      end

      # Query the number of returning visitors for a given time period
      # @param [DateTime] _start_date
      #
      # @return [OpenStruct] - Should contain attributes for date and returningVisitors
      # Example: <OpenStruct date="20180212", returningVisitors="5">
      def self.returning_visitors(_start_date)
        raise NotImplementedError, "#{self.class}#returning_visitors is unimplemented."
      end
    end
  end
end
