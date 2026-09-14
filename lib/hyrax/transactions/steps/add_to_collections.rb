# frozen_string_literal: true
require 'dry/monads'

module Hyrax
  module Transactions
    module Steps
      ##
      # Add a resource to collections via `ChangeSet`.
      #
      # Accepts `:collection_ids` and never retrieves the actual collections
      # from the persisted data. We trust that the identifiers passed refer to
      # actual, extant collections, and that the permissions to add to
      # collection membership have been established, or else that they'll be
      # validated prior to save.
      #
      # @since 3.0.0
      class AddToCollections
        include Dry::Monads[:result]

        ##
        # Add to collections by inserting collections to
        # `ChangeSet#member_of_collection_ids`.
        #
        # @param [Hyrax::ChangeSet] change_set
        # @param [Array<#to_s>] collection_ids
        #
        # @return [Dry::Monads::Result]
        def call(change_set, collection_ids: [])
          multi_membership_messages = check_multi_membership(change_set, collection_ids)
          return Failure(multi_membership_messages) if multi_membership_messages.present?

          change_set.member_of_collection_ids += collection_ids
          Success(change_set)
        end

        private

        def check_multi_membership(change_set, collection_ids)
          # Collections-in-collections have no multi-membership limit. Keyed on
          # the model, not the form class: an app may configure a
          # `pcdm_collection_form` outside the PcdmCollectionForm hierarchy.
          return if collection?(change_set)

          Hyrax::MultipleMembershipChecker
            .new(item: change_set)
            .check(collection_ids: [collection_ids], include_current_members: true)
        end

        def collection?(change_set)
          model = change_set.try(:model) || change_set
          Hyrax::ModelRegistry.collection_classes.any? { |klass| model.is_a?(klass) }
        end
      end
    end
  end
end
