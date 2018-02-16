module Hyrax
  module Analytics
    # @abstract Base class for Analytics services that support statistics needs in Hyrax.
    # Implementing subclasses must define `#connection` `#remote_statistics` and `#to_graph`
    class Base
      # Establish connection with the analytics service
      def self.connection
        raise NotImplementedError, "#{self.class}#connection is unimplemented."
      end

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
