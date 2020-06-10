# frozen_string_literal: true
module Hyrax
  class SelectCollectionTypePresenter
    # @param [CollectionType] a Hyrax::CollectionType
    def initialize(collection_type)
      @collection_type = collection_type
    end

    attr_reader :collection_type
    delegate :title, :description, :admin_set?, :id, to: :collection_type
  end
end
