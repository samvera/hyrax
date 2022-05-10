# frozen_string_literal: true
module Hyrax
  ##
  # Validates that the record passes the multiple membership requirements for collections.
  class CollectionMembershipValidator < ActiveModel::Validator
    ##
    # @param multiple_membership_checker
    def initialize(multiple_membership_checker: Hyrax::MultipleMembershipChecker, **options)
      @multiple_membership_checker = multiple_membership_checker
      super(options)
    end

    def validate(record)
      # collections-in-collections do not have multi-membership restrictions
      return true if record.is_a? Hyrax::Forms::PcdmCollectionForm
      checker = @multiple_membership_checker.new(item: nil)
      ids = collections_ids(record)

      errors = Array(checker.check(collection_ids: ids))
      record.errors[:member_of_collection_ids].concat(errors)
    end

    private

    def collections_ids(record)
      collection_ids = record.member_of_collection_ids.reject(&:blank?)

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
