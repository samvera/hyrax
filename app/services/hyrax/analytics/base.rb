module Hyrax
  module Analytics
    # @abstract Base class for Analytics services that support statistics needs in Hyrax.
    # Implementing subclasses must define `#connection` `#remote_statistics` and `#to_graph`
    class Base
      class << self
        include ActionDispatch::Routing::PolymorphicRoutes
        include Rails.application.routes.url_helpers
      end
      # Establish connection with the analytics service
      def self.connection
        raise NotImplementedError, "#{self.class}#connection is unimplemented."
      end

      # Query and generate a page-level analytics report for a given date range
      # @param [DateTime] _start_date
      # @param [DateTime] _page_token - It is expected that the report return batches of results if needed. The initial
      # default value is '0'
      #
      # Analytics this report is expected to return are:
      # 1. pageviews
      # 2. visitors
      # 3. sessions
      #
      # @return [Hash]<OpenStruct,String> - Should contain attributes for date, pagePath, pageviews, unique_visitors and
      # returning_visitors. It should also contain a next_page_token String.
      # Example: { rows: [<OpenStruct date="2018-03-15", pagePath: '/concern/generic_works/224', pageviews: '4',
      # visitors: '5', sesssions: '3'>], next_page_token: '10000' }
      def self.page_report(_start_date, _page_token)
        raise NotImplementedError, "#{self.class}#page_report is unimplemented."
      end

      # Query and generate a site-level analytics report for a given date range
      # @param [DateTime] _start_date
      # @param [DateTime] _page_token - It is expected that the report return batches of results if needed. The initial
      # default value is '0'
      #
      # Analytics this report is expected to return are:
      # 1. visitors
      # 2. sessions
      #
      # @return [Hash]<OpenStruct,String> - Should contain attributes for date, pagePath, pageviews, unique_visitors and
      # returning_visitors. It should also contain a next_page_token String.
      # Example: { rows: [<OpenStruct date="2018-03-15", visitors: '5', sessions: '3'>], next_page_token: '10000' }
      def self.site_report(_start_date, _page_token)
        raise NotImplementedError, "#{self.class}#site_report is unimplemented."
      end

      # Provide a listing of models to filter for in remote analytics queries
      # It iterates over the models available to the application and finds the path for the first object, removing the
      # identifier
      # This allows us to make more efficient remote batch queries, ignoring paths like /catalog which might otherwise
      # return a large result set we'll need to then ignore.
      #
      # Implementing subclasses should format filter queries as needed for the given API.
      # @return [Array] - List of current model paths in the application.
      # Example: ['/concern/generic_work', '/concern/namespaced_works/nested_works']
      def self.filters
        Hyrax::ExposedModelsRelation.new.allowable_types.map do |klass|
          next unless klass.first
          path = polymorphic_path(klass.first)
          path.slice(0..path.rindex('/'))
        end.compact
      end
    end
  end
end
