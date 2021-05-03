# frozen_string_literal: true
module Wings
  module CustomQueries
    class FindManyByAlternateIds
      # Custom query override specific to Wings
      # Use:
      #   Hyrax.custom_queries.find_many_by_alternate_ids(alternate_ids: ids, use_valkyrie: true)

      def self.queries
        [:find_many_by_alternate_ids]
      end

      attr_reader :query_service
      delegate :resource_factory, to: :query_service

      def initialize(query_service:)
        @query_service = query_service
      end

      # implements a combination of two Valkyrie queries:
      # => find_many_by_ids & find_by_alternate_identifier
      # @param alternate_ids [Enumerator<#to_s>] list of ids
      # @param use_valkyrie [boolean] defaults to true; optionally return ActiveFedora::Base objects if false
      # @return [Array<Valkyrie::Resource>, Array<ActiveFedora::Base>]
      def find_many_by_alternate_ids(alternate_ids:, use_valkyrie: Hyrax.config.use_valkryie?)
        af_objects = ActiveFedora::Base.find(alternate_ids.map(&:to_s))
        return af_objects unless use_valkyrie == true

        af_objects.map do |af_object|
          resource_factory.to_resource(object: af_object)
        end
      end
    end
  end
end
