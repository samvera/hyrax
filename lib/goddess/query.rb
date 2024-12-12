# frozen_string_literal: true
module Goddess
  module Query
    ##
    # This module provides the mechanisms for the four different query strategies:
    #
    # - {#find_multiple}
    # - {#find_single} :: find an instance and if none is found, raise an exception
    # - {#count_multiple}
    # - {#find_single_or_nil} :: as {#find_single} but if no instance is found return nil
    #
    # These private methods are responsible for querying the various inner services of the
    # QueryService adapter.
    module MethodMissingMachinations
      def model_class_for(model)
        internal_resource = model.respond_to?(:internal_resource) ? model.internal_resource : nil
        internal_resource&.safe_constantize || Wings::ModelRegistry.lookup(model)
      end

      def setup_model(model_name)
        model_name = model_class_for(model_name)
        model_name.respond_to?(:valkyrie_class) ? model_name.valkyrie_class : model_name
      end

      def total_results(result_sets)
        if result_sets.present?
          total_result = result_sets.inject([]) do |out, set|
            i = out.intersection(set)
            out + (set - i)
          end
          total_result
        else
          result_sets
        end
      end

      private

      def query_strategy_for_find_multiple(method_name, *args, **opts, &block)
        # I don't know how we'll handle sums; as we're looking for counts of distinct items.
        opts[:model] = setup_model(opts[:model]) if opts[:model]
        result_sets = []
        services.each do |service|
          next unless service.respond_to?(method_name)
          result = service.send(method_name, *args, **opts, &block)
          result_sets << result.to_a if result.present? && result.respond_to?(:any?) && result.any?
        rescue Valkyrie::Persistence::ObjectNotFoundError
          next
        end

        # We need to remove items in both sets, but not remove duplicates with in the set because
        # Valkyrie specifies that relationships can be duplicated (A can have [B, C, B, D] as
        # children)
        total_results(result_sets)
      end

      def query_strategy_for_count_multiple(method_name, *args, **opts, &block)
        opts[:model] = setup_model(opts[:model]) if opts[:model]
        result_sets = []
        services.each do |service|
          result = service.send(method_name, *args, **opts, &block)
          result_sets << result if result.present?
        rescue Valkyrie::Persistence::ObjectNotFoundError
          next
        end

        result_sets.max
      end

      # @note we dont have a good way to remove items in both from the count since we dont want to
      # load all of the items and de-dup them. There for we just return the highest number among the
      # counts. This will be inaccurate if you start adding new items to the target repo while
      # migrating
      def query_strategy_for_find_single(method_name, *args, **opts, &block)
        opts[:model] = setup_model(opts[:model]) if opts[:model]
        result = nil
        services.each do |service|
          next unless service.respond_to?(method_name)
          result = service.send(method_name, *args, **opts, &block)
          return result if result.present?
        rescue Valkyrie::Persistence::ObjectNotFoundError
          next
        end

        return result unless result.nil?
        raise Valkyrie::Persistence::ObjectNotFoundError
      end

      def query_strategy_for_find_single_or_nil(method_name, *args, **opts, &block)
        query_strategy_for_find_single(method_name, *args, **opts, &block)
      rescue Valkyrie::Persistence::ObjectNotFoundError
        nil
      end
    end

    extend ActiveSupport::Concern
    included do
      attr_reader :services
      delegate :orm_class, to: :resource_factory

      [:find_all,
       :find_all_of_model,
       :find_many_by_ids,
       :find_members,
       :find_references_by,
       :find_inverse_references_by,
       :find_inverse_references_by,
       :find_parents].each do |method_name|
        find_multiple(method_name)
      end

      [:find_by,
       :find_by_alternate_identifier].each do |method_name|
        find_single(method_name)
      end

      [:count_all_of_model].each do |method_name|
        count_multiple(method_name)
      end

      include MethodMissingMachinations
    end

    class_methods do # rubocop:disable Metrics/BlockLength
      def count_multiple(method_name)
        # look in all services, combine and uniq results
        define_method method_name do |*args, **opts, &block|
          query_strategy_for_count_multiple(__method__, *args, **opts, &block)
        end
      end

      def find_multiple(method_name)
        # look in all services, combine and uniq results
        define_method method_name do |*args, **opts, &block|
          query_strategy_for_find_multiple(__method__, *args, **opts, &block)
        end
      end

      def find_single(method_name)
        define_method method_name do |*args, **opts, &block|
          query_strategy_for_find_single(__method__, *args, **opts, &block)
        end
      end
    end

    # @param [QueryService] query_service
    def initialize(*services)
      @services = services
      setup_custom_queries
    end

    # rubocop:disable Metrics/MethodLength
    def setup_custom_queries
      # load all the sql based custom queries
      [
        Hyrax::CustomQueries::Navigators::CollectionMembers,
        Hyrax::CustomQueries::Navigators::ChildCollectionsNavigator,
        Hyrax::CustomQueries::Navigators::ParentCollectionsNavigator,
        Hyrax::CustomQueries::Navigators::ChildFileSetsNavigator,
        Hyrax::CustomQueries::Navigators::ChildWorksNavigator,
        Hyrax::CustomQueries::Navigators::FindFiles,
        Hyrax::CustomQueries::FindAccessControl,
        Hyrax::CustomQueries::FindCollectionsByType,
        Hyrax::CustomQueries::FindFileMetadata,
        Hyrax::CustomQueries::FindIdsByModel,
        Hyrax::CustomQueries::FindManyByAlternateIds,
        Hyrax::CustomQueries::FindModelsByAccess,
        Hyrax::CustomQueries::FindCountBy,
        Hyrax::CustomQueries::FindByDateRange
      ].each do |handler|
        services[0].custom_queries.register_query_handler(handler)
      end
    end
    # rubocop:enable Metrics/MethodLength
  end
end
