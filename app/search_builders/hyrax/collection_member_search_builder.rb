module Hyrax
  # This search builder requires that a accessor named "collection" exists in the scope
  # TODO it would be better to pass collection_id in.
  class CollectionMemberSearchBuilder < ::SearchBuilder
    include Hyrax::FilterByType
    attr_reader :collection_id, :search_includes_models

    class_attribute :collection_membership_field
    self.collection_membership_field = 'nesting_collection__parent_ids_ssim'

    # Defines which search_params_logic should be used when searching for Collection members
    self.default_processor_chain += [:member_of_collection]

    delegate :collection, to: :scope

    # @param [Controller] The controller object
    # @param [Symbol] :works, :collections, (anything else = both)
    def initialize(scope,
                   search_includes_models: :works)
      @search_includes_models = search_includes_models
      super(scope)
    end

    # include filters into the query to only include the collection memebers
    def member_of_collection(solr_parameters)
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << "#{collection_membership_field}:#{collection_id}"
    end

    # This overrides the models in FilterByType
    def models
      case search_includes_models
      when :collections
        collection_classes
      when :works
        work_classes
      else super # super includes both works and collections
      end
    end

    private

      def collection_id
        collection.id || raise("Collection does not have an identifier")
      end
  end
end
