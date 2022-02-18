# frozen_string_literal: true
module Hyrax
  # validates that the title has at least one title
  class CollectionMembershipValidator < ActiveModel::Validator
    def validate(record)
      errs = update_collections(record)
      return if errs.blank?
      record.errors[:member_of_collection_ids] << errs
    end

    private

    # @return errs if any occurred; otherwise, false
    # @note Always ok to remove, so do that first.  Avoids add conflict when the
    #    conflicting collection is one that was being removed.
    def update_collections(record)
      return if record.member_of_collections_attributes.blank?
      remove_collections(record)
      add_collections(record)
    end

    def remove_collections(record)
      record.member_of_collection_ids -= collection_ids_to_remove(record)
    end

    # @return errs if any occurred; otherwise, false
    def add_collections(record)
      ids_to_add = collection_ids_to_add(record)
      errs = check_multi_membership(record, ids_to_add)
      return errs if errs.present?
      record.member_of_collection_ids += ids_to_add
      false
    end

    def check_multi_membership(record, collection_ids)
      # collections in collections do not have multi-membership restrictions
      return if record.is_a? Hyrax::Forms::PcdmCollectionForm

      Hyrax::MultipleMembershipChecker
        .new(item: record)
        .check(collection_ids: collection_ids, include_current_members: true)
    end

    def collection_ids_to_add(record)
      record.member_of_collections_attributes
            .each_value
            .select { |h| h["_destroy"] == "false" }
            .map { |col_data| Valkyrie::ID.new(col_data["id"]) }
    end

    def collection_ids_to_remove(record)
      record.member_of_collections_attributes
            .each_value
            .select { |h| h["_destroy"] == "true" }
            .map { |col_data| Valkyrie::ID.new(col_data["id"]) }
    end
  end
end
