# frozen_string_literal: true
module Hyrax
  class SelectCollectionTypePresenter
    ##
    # @!attribute [r] collection_type
    #   @return [CollectionType]
    attr_reader :collection_type

    ##
    # @param [CollectionType] collection_type a Hyrax::CollectionType
    def initialize(collection_type)
      @collection_type = collection_type
    end
    ##
    # @!method admin_set?
    #   @return [Boolean]
    # @!method description
    #   @see CollectionType#description
    # @!method id
    #   @see CollectionType#id
    # @!method title
    #   @see CollectionType#title
    delegate :title, :description, :admin_set?, :id, to: :collection_type
  end
end
