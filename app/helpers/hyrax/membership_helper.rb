# frozen_string_literal: true

module Hyrax
  module MembershipHelper
    ##
    # @param resource [#member_of_collection_ids, #member_of_collections_json]
    #
    # @return [String] JSON for `data-members`
    #
    # @todo implement for objects with only an ids field
    #
    # @see app/assets/javascripts/hyrax/relationships.js
    def member_of_collections_json(resource)
      resource.try(:member_of_collections_json) ||
        [].to_json
    end
  end
end
