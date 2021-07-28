# frozen_string_literal: true
module Hyrax
  ##
  # @deprecated
  # This class is being replaced by Hyrax::SolrQueryService.
  #
  # Methods in this class are from/based on ActiveFedora::SolrQueryBuilder
  #
  # @see Hyrax::SolrQueryService
  class SolrQueryBuilderService
    class << self
      # Construct a solr query for a list of ids
      # This is used to get a solr response based on the list of ids in an object's RELS-EXT relationhsips
      # If the id_array is empty, defaults to a query of "id:NEVER_USE_THIS_ID", which will return an empty solr response
      # @param [Array] id_array the ids that you want included in the query
      # @return [String] a solr query
      # @example
      #   construct_query_for_ids(['a1', 'b2'])
      #   # => "{!terms f=id}a1,b2"
      # @deprecated
      def construct_query_for_ids(id_array)
        Deprecation.warn("'##{__method__}' will be removed in Hyrax 4.0.  " \
                         "Instead, use 'Hyrax::SolrQueryService.new.with_ids'.")
        ids = id_array.reject(&:blank?)
        return "id:NEVER_USE_THIS_ID" if ids.empty?
        Hyrax::SolrQueryService.new.with_ids(ids: id_array).build
      end

      # Construct a solr query from a list of pairs (e.g. [field name, values])
      # @param [Hash] field_pairs a list of pairs of property name and values
      # @param [String] join_with the value we're joining the clauses with (default: ' AND ')
      # @param [String] type of query to run. Either 'raw' or 'field' (default: 'field')
      # @return [String] a solr query
      # @example
      #   construct_query([['library_id_ssim', '123'], ['owner_ssim', 'Fred']])
      #   # => "_query_:\"{!field f=library_id_ssim}123\" AND _query_:\"{!field f=owner_ssim}Fred\""
      # @deprecated
      def construct_query(field_pairs, join_with = default_join_with, type = 'field')
        Deprecation.warn("'##{__method__}' will be removed in Hyrax 4.0.  " \
                         "Instead, use 'Hyrax::SolrQueryService.new.with_field_pairs'.")
        Hyrax::SolrQueryService.new.with_field_pairs(field_pairs: field_pairs,
                                                     join_with: join_with,
                                                     type: type).build
      end

      # @deprecated
      def default_join_with
        Deprecation.warn("'##{__method__}' will be removed in Hyrax 4.0.  " \
                         "There will not be a replacement for this method. See Hyrax::SolrQueryService which is replacing this class.")
        ' AND '
      end

      # Construct a solr query from a list of pairs (e.g. [field name, values]) including the model (e.g. Collection, Monograph)
      # @param [Class] model class
      # @param [Hash] field_pairs a list of pairs of property name and values
      # @param [String] join_with the value we're joining the clauses with (default: ' AND ')
      # @param [String] type of query to run. Either 'raw' or 'field' (default: 'field')
      # @return [String] a solr query
      # @example
      #   construct_query(Collection, [['library_id_ssim', '123'], ['owner_ssim', 'Fred']])
      #   # => "_query_:\"{!field f=has_model_ssim}Collection\" AND _query_:\"{!field f=library_id_ssim}123\" AND _query_:\"{!field f=owner_ssim}Fred\""
      # @deprecated
      def construct_query_for_model(model, field_pairs, join_with = default_join_with, type = 'field')
        Deprecation.warn("'##{__method__}' will be removed in Hyrax 4.0.  " \
                         "Instead, use 'Hyrax::SolrQueryService.new.with_model'.")
        field_pairs["has_model_ssim"] = model.to_s
        Hyrax::SolrQueryService.new.with_field_pairs(field_pairs: field_pairs,
                                                     join_with: join_with,
                                                     type: type).build
      end

      private

      # @param [Array<Array>] pairs a list of (key, value) pairs. The value itself may
      # @param [String] type  The type of query to run. Either 'raw' or 'field'
      # @return [Array] a list of solr clauses
      def pairs_to_clauses(pairs, type)
        pairs.flat_map do |field, value|
          condition_to_clauses(field, value, type)
        end
      end

      # @param [String] field
      # @param [String, Array<String>] values
      # @param [String] type The type of query to run. Either 'raw' or 'field'
      # @return [Array<String>]
      def condition_to_clauses(field, values, type)
        values = Array(values)
        values << nil if values.empty?
        values.map do |value|
          if value.present?
            query_clause(type, field, value)
          else
            # Check that the field is not present. In SQL: "WHERE field IS NULL"
            "-#{field}:[* TO *]"
          end
        end
      end

      # Create a raw query clause suitable for sending to solr as an fq element
      # @param [String] type The type of query to run. Either 'raw' or 'field'
      # @param [String] key
      # @param [String] value
      def query_clause(type, key, value)
        "_query_:\"{!#{type} f=#{key}}#{value.gsub('"', '\"')}\""
      end
    end
  end
end
