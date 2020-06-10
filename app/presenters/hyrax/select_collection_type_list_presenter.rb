# frozen_string_literal: true
module Hyrax
  # Presents the list of collection type options that a user may choose from when deciding to create a new work
  class SelectCollectionTypeListPresenter
    # @param current_user [User]
    def initialize(current_user)
      @current_user = current_user
    end

    class_attribute :row_presenter
    self.row_presenter = SelectCollectionTypePresenter

    # @return [Boolean] are there many different types to choose?
    def many?
      authorized_collection_types.size > 1
    end

    # @return [Boolean] are there any authorized types?
    def any?
      return true if authorized_collection_types.present?
      false
    end

    # Return an array of authorized collection types.
    def authorized_collection_types
      @authorized_collection_types ||= Hyrax::CollectionTypes::PermissionsService.can_create_collection_types(user: @current_user)
    end

    # Return or yield the first type in the list. This is used when the list
    # only has a single element.
    # @yieldparam [CollectionType] a Hyrax::CollectionType
    # @return [CollectionType] a Hyrax::CollectionType
    def first_collection_type
      yield(authorized_collection_types.first) if block_given?
      authorized_collection_types.first
    end

    # @yieldparam [SelectCollectionTypePresenter] a presenter for the collection
    def each
      authorized_collection_types.each { |type| yield row_presenter.new(type) }
    end
  end
end
