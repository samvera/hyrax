# frozen_string_literal: true
module Hyrax
  # validates that the title has at least one title
  class CollectionMembershipValidator < ActiveModel::Validator
    def validate(record)
      update_collections(record)
      validation = validate_multi_membership(record)
      return if validation == true
      record.errors[:member_of_collection_ids] << validation
    end

    private

    def validate_multi_membership(record)
      # collections-in-collections do not have multi-membership restrictions
      return true if record.is_a? Hyrax::Forms::PcdmCollectionForm

      Hyrax::MultipleMembershipChecker.new(item: record).validate
    end

    def update_collections(record)
      record.member_of_collection_ids = collections_ids(record)
      record.member_of_collection_ids.uniq!
    end

    def collections_ids(record)
      collection_ids = []
      if record.member_of_collections_attributes.present?
        record.member_of_collections_attributes
              .each do |_k, h|
                next if h["_destroy"] == "true"
                collection_ids << Valkyrie::ID.new(h["id"])
              end
      end
      collection_ids
    end
  end
end
