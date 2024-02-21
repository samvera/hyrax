# frozen_string_literal: true
module Goddess
  class CustomQueryContainer < Valkyrie::Persistence::CustomQueryContainer
    include Goddess::Query::MethodMissingMachinations
    ##
    # @!group Class Attributes
    #
    # @!attribute :known_custom_queries_and_their_strategies [r|w]
    #   @return [Hash<Symbol,Symbol>]
    #   Valid strategies are :find_multiple
    #   @see Goddess::Query::MethodMissingMachinations
    class_attribute(:known_custom_queries_and_their_strategies,
                    default: {
                      find_parents: :find_multiple,
                      find_ids_by_model: :find_multiple,
                      find_collections_by_type: :find_multiple
                    })
    class_attribute(:fallback_query_strategy, default: :find_single)
    # @!endgroup Class Attributes
    ##

    def services
      @services ||= query_service.services.map(&:custom_queries)
    end

    private

    def method_missing(method_name, *args, **opts, &block)
      return super unless services.detect { |service| service.respond_to?(method_name) }

      strategy = known_custom_queries_and_their_strategies.fetch(method_name, fallback_query_strategy)
      dispatch_method_name = "query_strategy_for_#{strategy}"

      # We want to check for private methods
      return super unless respond_to?(dispatch_method_name, true)
      send(dispatch_method_name, method_name, *args, **opts, &block)
    end

    def respond_to_missing?(method_name, _include_private = false)
      services.detect { service.respond_to?(method_name) }.present? || super
    end
  end
end
