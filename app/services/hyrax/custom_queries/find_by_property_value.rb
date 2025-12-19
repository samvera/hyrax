# frozen_string_literal: true

module Hyrax
  module CustomQueries
    ##
    # Finds resources for arbitrary properties using the Solr index.
    # @see https://github.com/samvera/valkyrie/wiki/Queries#custom-queries
    class FindByPropertyValue
      def self.queries
        [:find_ids_by_property_pairs,
         :find_many_by_property_pairs,
         :find_many_by_property_value,
         :find_by_property_value]
      end

      def initialize(query_service:, query_rows: 1_000)
        @query_service = query_service
        @query_rows = query_rows
      end

      ##
      # Returns ids for resources matching all specified property/value pairs.
      # @param pairs [Hash<String, String>] properties and values to match
      # @param field_types Hash,Symbol which solr field suffix to use; Use a hash to set per field
      # @param options Hash options to pass to solr
      #
      # @return [Array<String>] found ids, if any
      def find_ids_by_property_pairs(pairs:, field_types: :symbol, **options)
        options = { rows: @query_rows }.merge(options)
        query = pairs.map do |k, v|
          type = if field_types.is_a? Hash
                   field_types[k] || :symbol
                 else
                   field_types
                 end
          "+#{Hyrax.config.index_field_mapper.solr_name(k, type)}:\"#{RSolr.solr_escape(v)}\""
        end
        response = Hyrax::SolrService.query_result(query.join(' '), fl: 'id', **options)
        response['response']['docs'].map { |doc| doc['id'] }
      end

      ##
      # Returns resources matching all specified property/value pairs.
      # @param pairs [Hash<String, String>] properties and values to match
      # @param field_types Hash,Symbol which solr field suffix to use; Use a hash to set per field
      # @param options Hash options to pass to solr
      #
      # @return [Array<Valkyrie::Resource>] found resources, if any
      def find_many_by_property_pairs(pairs:, field_types: :symbol, **options)
        found_ids = find_ids_by_property_pairs(pairs: pairs, field_types: field_types, **options)
        @query_service.find_many_by_ids(ids: found_ids)
      end

      ##
      # Returns resources matching the specified property and value.
      # @param property [#to_s] the name of the property we're attempting to query.
      # @param value [#to_s] the property value we're trying to match.
      # @param field_type Symbol which solr field suffix to use
      # @param options Hash options to pass to solr
      #
      # @return [Array<Valkyrie::Resource>] found resources, if any
      def find_many_by_property_value(property:, value:, field_type: :symbol, **options)
        find_many_by_property_pairs(pairs: { property => value }, field_types: field_type, **options)
      end

      ##
      # Returns one resource matching the specified property and value.
      # @param property [#to_s] the name of the property we're attempting to query.
      # @param value [#to_s] the property value we're trying to match.
      # @param field_type Symbol which solr field suffix to use
      # @param options Hash options to pass to solr
      #
      # @return [NilClass] when no record was found
      # @return [Valkyrie::Resource] when a resource was found
      def find_by_property_value(property:, value:, field_type: :symbol, **options)
        options[:rows] = 1
        find_many_by_property_value(property: property, value: value, field_type: field_type, **options).first
      end
    end
  end
end
