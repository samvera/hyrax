# frozen_string_literal: true
module Hyrax
  # This search builder requires that a accessor named "collection" exists in the scope
  class CollectionMemberSearchBuilder < ::Hyrax::CollectionSearchBuilder
    include Hyrax::FilterByType
    attr_accessor :collection, :search_includes_models

    class_attribute :collection_membership_field
    self.collection_membership_field = 'member_of_collection_ids_ssim'

    # Defines which search_params_logic should be used when searching for Collection members
    self.default_processor_chain += [:member_of_collection]

    # @param [Object] scope Typically the controller object
    # @param [Symbol] search_includes_models +:works+ or +:collections+; (anything else retrieves both)
    def initialize(*args,
                   scope: nil,
                   collection: nil,
                   search_includes_models: nil)
      @collection = collection || (scope.context[:collection] if scope&.respond_to?(:context))
      @search_includes_models = search_includes_models || :works

      if args.any?
        super(*args)
      else
        super(scope)
      end
    end

    # include filters into the query to only include the collection memebers
    def member_of_collection(solr_parameters)
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << "#{collection_membership_field}:#{@collection.id}"
    end

    private

    def only_works?
      @search_includes_models == :works
    end

    def only_collections?
      @search_includes_models == :collections
    end
  end
end
