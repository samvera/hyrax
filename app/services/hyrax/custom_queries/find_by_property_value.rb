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
      # @param field_suffix Hash,Symbol which solr field suffix to use; Use a hash to set per field pair
      # @param options Hash options to pass to solr
      #
      # @return [Array<String>] found ids, if any
      def find_ids_by_property_pairs(pairs:, field_suffix: :ssim, **options)
        options = { rows: @query_rows }.merge(options)
        query = pairs.map do |k, v|
          suffix = if field_suffix.is_a? Hash
                     field_suffix[k] || :ssim
                   else
                     field_suffix
                   end
          "+#{k}_#{suffix}:\"#{RSolr.solr_escape(v)}\""
        end
        response = Hyrax::SolrService.query_result(query.join(' '), fl: 'id', **options)
        response['response']['docs'].map { |doc| doc['id'] }
      end

      ##
      # Returns resources matching all specified property/value pairs.
      # @param pairs [Hash<String, String>] properties and values to match
      # @param field_suffix Hash,Symbol which solr field suffix to use; Use a hash to set per field pair
      # @param options Hash options to pass to solr
      #
      # @return [Array<Valkyrie::Resource>] found resources, if any
      def find_many_by_property_pairs(pairs:, field_suffix: :ssim, **options)
        found_ids = find_ids_by_property_pairs(pairs: pairs, field_suffix: field_suffix, **options)
        @query_service.find_many_by_ids(ids: found_ids).to_a  # Wings emits an Enumerator
      end

      ##
      # Returns resources matching the specified property and value.
      # @param property [#to_s] the name of the property we're attempting to query.
      # @param value [#to_s] the property value we're trying to match.
      # @param field_suffix Symbol which solr field suffix to use
      # @param search_field String alt way to set property and suffix for compatibility
      # @param options Hash options to pass to solr
      #
      # @return [Array<Valkyrie::Resource>] found resources, if any
      def find_many_by_property_value(property:, value:, field_suffix: :ssim, search_field: nil, **options)
        if search_field
          search_field_array = search_field.split('_')
          field_suffix = search_field_array.last
          property = search_field_array[0...-1].join('_')
        end
        find_many_by_property_pairs(pairs: { property => value }, field_suffix: field_suffix, **options)
      end

      ##
      # Returns one resource matching the specified property and value.
      # @param property [#to_s] the name of the property we're attempting to query.
      # @param value [#to_s] the property value we're trying to match.
      # @param field_suffix Symbol which solr field suffix to use
      # @param search_field String alt way to set property and suffix for compatibility
      # @param options Hash options to pass to solr
      #
      # @return [NilClass] when no record was found
      # @return [Valkyrie::Resource] when a resource was found
      def find_by_property_value(property:, value:, field_suffix: :ssim, search_field: nil, **options)
        options[:rows] = 1
        find_many_by_property_value(property: property, value: value,
                                    field_suffix: field_suffix, search_field: search_field, **options).first
      end
    end
  end
end
