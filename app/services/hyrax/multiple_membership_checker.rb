module Hyrax
  # Service class for checking an item's collection memberships, to
  # make sure that the item is not added to multiple single-membership
  # collections
  class MultipleMembershipChecker
    attr_reader :item

    # @param [#member_of_collection_ids] item an object that belongs to
    #   collections
    def initialize(item:)
      @item = item
    end

    # @api public
    #
    # Scan a list of collection_ids for multiple single-membership collections.
    #
    # Collections that have a collection type declaring
    # `allow_multiple_membership` as `false` require that its members do not
    # also belong to other collections of the same type.
    #
    # There are two contexts in which memberships are checked: when doing a
    # wholesale replacement and when making an incremental change, such as
    # adding a single collection membership to an object. In the former case,
    # `#check` only scans the passed-in collection identifiers. In the latter,
    # `#check` must also scan the collections to which an object currently
    # belongs for potential conflicts.
    #
    # @param collection_ids [Array<String>] a list of collection identifiers
    # @param include_current_members [Boolean] a flag to also scan an object's
    #   current collection memberships
    #
    # @return [nil, String] nil if no conflicts; an error message string if so
    def check(collection_ids:, include_current_members: false)
      # short-circuit if no single membership types have been created
      return if single_membership_types.blank?
      # short-circuit if no new single_membership_collections passed in
      new_single_membership_collections = single_membership_collections(collection_ids)
      return if new_single_membership_collections.blank?
      collections_to_check = new_single_membership_collections
      # No need to check current members when coming in from the ActorStack, which does a wholesale collection membership replacement
      collections_to_check |= single_membership_collections(item.member_of_collection_ids) if include_current_members
      problematic_collections = collections_to_check.uniq(&:id)
                                                    .group_by(&:collection_type_gid)
                                                    .select { |_gid, list| list.count > 1 }
      return if problematic_collections.blank?
      build_error_message(problematic_collections)
    end

    private

      def single_membership_collections(collection_ids)
        return [] if collection_ids.blank?
        Collection.where(id: collection_ids, collection_type_gid_ssim: single_membership_types)
      end

      def single_membership_types
        Hyrax::CollectionType.where(allow_multiple_membership: false).map(&:gid)
      end

      def build_error_message(problematic_collections)
        error_message_clauses = problematic_collections.map do |gid, list|
          I18n.t('hyrax.admin.collection_types.multiple_membership_checker.error_type_and_collections',
                 type: collection_type_title_from_gid(gid),
                 collections: collection_titles_from_list(list))
        end
        "#{I18n.t('hyrax.admin.collection_types.multiple_membership_checker.error_preamble')}#{error_message_clauses.join('; ')}"
      end

      def collection_type_title_from_gid(gid)
        Hyrax::CollectionType.find_by_gid(gid).title
      end

      def collection_titles_from_list(collection_list)
        collection_list.each do |collection|
          collection.title.first
        end.to_sentence
      end
  end
end
