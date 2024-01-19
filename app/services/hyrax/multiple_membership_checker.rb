# frozen_string_literal: true
module Hyrax
  # Service class for checking an item's collection memberships, to
  # make sure that the item is not added to multiple single-membership
  # collections
  class MultipleMembershipChecker
    attr_reader :item

    # @param [#member_of_collection_ids] item an object that belongs to collections
    def initialize(item:)
      @item = item
    end

    # @api public
    #
    # Validate member_of_collection_ids does not have any membership conflicts
    # based on the collection types of the members.
    #
    # Collections that have a collection type declaring
    # `allow_multiple_membership` as `false` require that its members do not
    # also belong to other collections of the same type.
    #
    # @return [True, String] true if no conflicts; otherwise, an error message string
    # @deprecated Use #check instead; for removal in 4.0.0
    def validate
      Deprecation.warn "#{self.class}##{__method__} is deprecated; use #check instead."
      return true if item.member_of_collection_ids.empty? || item.member_of_collection_ids.count <= 1
      return true unless single_membership_collection_types_exist?

      collections_to_check = filter_to_single_membership_collections(item.member_of_collection_ids)
      problematic_collections = check_collections(collections_to_check)
      errs = build_error_message(problematic_collections)
      errs.presence || true
    end

    # @api public
    #
    # Scan a list of collection_ids for multiple single-membership collections.
    #
    # Collections that have a collection type declaring
    # `allow_multiple_membership` as `false` require that its members do not
    # also belong to other collections of the same type.
    #
    # @param collection_ids [Array<String>] a list of collection identifiers
    # @param include_current_members [Boolean] if true, include item's existing
    #   collections in check; else if false, check passed in collections only
    #   * use `false` when collection_ids includes proposed new collections and existing
    #     collections (@see Hyrax::Actors::CollectionsMembershipActor #valid_membership?)
    #   * use `true` when collection_ids includes proposed new collections only
    #     (@see Hyrax::Collections::CollectionMemberService #add_member)
    #
    # @return [nil, String] nil if no conflicts; an error message string if so
    def check(collection_ids:, include_current_members: false)
      return unless single_membership_collection_types_exist?

      proposed_single_membership_collections = filter_to_single_membership_collections(collection_ids)
      return if proposed_single_membership_collections.blank?

      collections_to_check = collections_to_check(proposed_single_membership_collections,
                                                  include_current_members)
      problematic_collections = check_collections(collections_to_check)
      build_error_message(problematic_collections)
    end

    private

    # @return [Boolean] true if there a any collection types that restrict membership
    def single_membership_collection_types_exist?
      single_membership_collection_types_gids.present?
    end

    # @return [Array<String] global ids of collection types that restrict membership
    def single_membership_collection_types_gids
      @single_membership_collection_types_gids ||=
        Hyrax::CollectionType.gids_that_do_not_allow_multiple_membership&.map(&:to_s)
    end

    # @return [Array<Hyrax::PcdmCollection>] list of collection instances for single membership collections
    def filter_to_single_membership_collections(collection_ids)
      return [] if collection_ids.blank?
      field_pairs = {
        Hyrax.config.collection_type_index_field.to_sym => single_membership_collection_types_gids
      }
      Hyrax::SolrQueryService.new
                             .with_generic_type(generic_type: "Collection")
                             .with_ids(ids: Array(collection_ids).map(&:to_s))
                             .with_field_pairs(field_pairs: field_pairs, join_with: ' OR ')
                             .get_objects(use_valkyrie: true).to_a
    end

    # @param proposed [Array<Hyrax::PcdmCollection>] collections with restricted membership that are being added
    # @param include_current_members [Boolean] true if current collections for item should also be checked
    # @return [Array<Hyrax::PcdmCollection>] collections with restricted membership
    def collections_to_check(proposed, include_current_members)
      # ActorStack does a wholesale collection membership replacement, such that
      # proposed collections include existing and new collections.  Parameter
      # `include_current_members` will be false when coming from the actor stack
      # to prevent member items being passed in and then added here as well.
      return proposed unless include_current_members
      proposed | filter_to_single_membership_collections(item.member_of_collection_ids)
    end

    # @param collections_to_check [Array<Hyrax::PcdmCollection>] collections with restricted membership
    # @return [Array<Array>] collections groups by collection type
    # @example example return result
    #   [
    #     [
    #       <Collection(id: 1, collection_type_gid: 1, ...)>,
    #       <Collection(id: 4, collection_type_gid: 1, ...)>
    #     ],
    #     [
    #       <Collection(id: 13, collection_type_gid: 8, ...)>,
    #       <Collection(id: 26, collection_type_gid: 8, ...)>
    #     ]
    #   ]
    def check_collections(collections_to_check)
      # uniq insures we include a collection only once when it is in the list multiple
      # group_by groups collections of the same collection type together
      # select keeps only collection type groups that have more than one collection
      #   of the single collection type
      collections_to_check.uniq(&:id)
                          .group_by(&:collection_type_gid)
                          .select { |_gid, list| list.count > 1 }
    end

    # @return [nil, String] nil if no errors; otherwise, errors appended into a single human readable message
    def build_error_message(problematic_collections)
      return if problematic_collections.blank?
      error_message_clauses = problematic_collections.map do |gid, list|
        I18n.t('hyrax.admin.collection_types.multiple_membership_checker.error_type_and_collections',
               type: collection_type_title_from_gid(gid),
               collections: collection_titles_from_list(list))
      end
      "#{I18n.t('hyrax.admin.collection_types.multiple_membership_checker.error_preamble')}" \
        "#{error_message_clauses.join('; ')}"
    end

    # @return [String] title of the collection type
    def collection_type_title_from_gid(gid)
      Hyrax::CollectionType.find_by_gid(gid).title
    end

    # @return [String] comma separated (with and before final) list of titles
    # @example "Title 1, Title 2, and Title 3"
    def collection_titles_from_list(collection_list)
      collection_list.map do |collection|
        collection.title.first
      end.sort.to_sentence
    end
  end
end
