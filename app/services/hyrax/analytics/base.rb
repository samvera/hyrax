module Hyrax
  module Analytics
    # @abstract Base class for Analytics services that support statistics needs in Hyrax.
    # Implementing subclasses must define `#connection` `#remote_statistics` and `#to_graph`
    class Connector
      # Establish connection with the analytics service
      def self.connection
        raise NotImplementedError, "#{self.class}#connection is unimplemented."
      end

      # Used by Hyrax::Statistic to perform live queries against the remote service
      # @param start_date [DateTime]
      # @param object [ActiveFedora::Base??] probably a better type for this
      # @param query_type
      #
      # return [Enumerable] of objects to cache locally in DB
      # TODO: decide best place for query types: pageview, download, returning visitors,  new visitors,..
      def self.remote_statistics(_start_date, _object, _query_type)
        raise NotImplementedError, "#{self.class}#remote_statistics is unimplemented."
      end

      # OR, define explicit query methods for each query?
      # Examples
      def self.pageviews(_start_date, _object)
        raise NotImplementedError, "#{self.class}#pageviews is unimplemented."
      end

      def self.downloads(_start_date, _object)
        raise NotImplementedError, "#{self.class}#downloads is unimplemented."
      end

      def self.visitors(_start_date)
        raise NotImplementedError, "#{self.class}#visitors is unimplemented."
      end

      def self.returning_visitors(_start_date)
        raise NotImplementedError, "#{self.class}#returning_visitors is unimplemented."
      end
    end
  end
end
