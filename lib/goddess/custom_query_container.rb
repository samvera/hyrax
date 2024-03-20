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
    #   @todo Audit the current custom queries and assign strategies.
    class_attribute(:known_custom_queries_and_their_strategies,
                    default: {
                      find_by_date_range: :find_multiple,
                      find_child_collection_ids: :find_multiple,
                      find_child_collections: :find_multiple,
                      find_child_file_set_ids: :find_multiple,
                      find_child_file_sets: :find_multiple,
                      find_child_fileset_ids: :find_multiple,
                      find_child_filesets: :find_multiple,
                      find_child_work_ids: :find_multiple,
                      find_child_works: :find_multiple,
                      find_collections_by_type: :find_multiple,
                      find_collections_for: :find_multiple,
                      find_count_by: :count_multiple,
                      find_extracted_text: :find_single,
                      find_file_metadata_by: :find_single,
                      find_file_metadata_by_alternate_identifier: :find_single,
                      find_files: :find_multiple,
                      find_ids_by_model: :find_multiple,
                      find_many_by_alternate_ids: :find_multiple,
                      find_many_file_metadata_by_ids: :find_multiple,
                      find_many_file_metadata_by_use: :find_multiple,
                      find_members_of: :find_multiple,
                      find_models_by_access: :find_multiple,
                      find_original_file: :find_single,
                      find_parent_collection_ids: :find_multiple,
                      find_parent_collections: :find_multiple,
                      find_parent_work: :find_single_or_nil,
                      find_parent_work_id: :find_single_or_nil,
                      find_parents: :find_multiple,
                      find_thumbnail: :find_single,
                      find_access_control_for: :find_single
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
      services.detect { |service| service.respond_to?(method_name) }.present? || super
    end
  end
end
