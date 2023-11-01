# frozen_string_literal: true
module Hyrax
  module Collections
    ##
    # Retrieves collection members
    class CollectionMemberService
      ##
      # @param scope [#repository] Typically a controller object which responds to :repository
      # @param [::Collection] collection
      # @param [ActionController::Parameters] params the query params
      # @param [ActionController::Parameters] user_params
      # @param [::Ability] current_ability
      # @param [Class] search_builder_class a {::SearchBuilder}
      def initialize(scope:, collection:, params:, user_params: nil, current_ability: nil, search_builder_class: Hyrax::CollectionMemberSearchBuilder) # rubocop:disable Metrics/ParameterLists
        Deprecation.warn("'##{__method__}' will be removed in Hyrax 4.0.  " \
                         "Instead, use the same method in 'Hyrax::Collections::CollectionMemberSearchService'.")
        @member_search_service = Hyrax::Collections::CollectionMemberSearchService(scope: scope,
                                                                                   collection: collection,
                                                                                   params: params,
                                                                                   user_params: user_params,
                                                                                   current_ability: current_ability,
                                                                                   search_builder_class: search_builder_class)
      end

      ##
      # @api public
      #
      # Collections which are members of the given collection
      #
      # @return [Blacklight::Solr::Response] (up to 50 solr documents)
      def available_member_subcollections
        Deprecation.warn("'##{__method__}' will be removed in Hyrax 4.0.  " \
                         "Instead, use the same method in 'Hyrax::Collections::CollectionMemberSearchService'.")
        @member_search_service.available_member_subcollections
      end

      ##
      # @api public
      #
      # Works which are members of the given collection
      #
      # @return [Blacklight::Solr::Response]
      def available_member_works
        Deprecation.warn("'##{__method__}' will be removed in Hyrax 4.0.  " \
                         "Instead, use the same method in 'Hyrax::Collections::CollectionMemberSearchService'.")
        @member_search_service.available_member_works
      end

      ##
      # @api public
      #
      # Work ids of the works which are members of the given collection
      #
      # @return [Blacklight::Solr::Response]
      def available_member_work_ids
        Deprecation.warn("'##{__method__}' will be removed in Hyrax 4.0.  " \
                         "Instead, use the same method in 'Hyrax::Collections::CollectionMemberSearchService'.")
        @member_search_service.available_member_work_ids
      end

      class << self
        # Check if a work or collection is already a member of a collection
        # @param collection_id [Valkyrie::ID] the id of the parent collection
        # @param member [Hyrax::Resource] the child collection and/or child work to check
        # @return [Boolean] true if already in the member set; otherwise, false
        def member?(collection_id:, member:)
          member.member_of_collection_ids.include? collection_id
        end

        # Add works and/or collections as members of a collection
        # @param collection_id [Valkyrie::ID] the id of the parent collection
        # @param new_member_ids [Enumerable<Valkyrie::ID>] the ids of the new child collections and/or child works
        # @return [Enumerable<Hyrax::Resource>] updated member resources
        def add_members_by_ids(collection_id:, new_member_ids:, user:)
          new_members = Hyrax.query_service.find_many_by_ids(ids: new_member_ids)
          add_members(collection_id: collection_id, new_members: new_members, user: user)
        end

        # Add works and/or collections as members of a collection
        # @param collection_id [Valkyrie::ID] the id of the parent collection
        # @param new_members [Enumerable<Hyrax::Resource>] the new child collections and/or child works
        # @return [Enumerable<Hyrax::Resource>] updated member resources
        def add_members(collection_id:, new_members:, user:)
          messages = []
          new_members.map do |new_member|
            add_member(collection_id: collection_id, new_member: new_member, user: user)
          rescue Hyrax::SingleMembershipError => err
            messages += [err.message]
          end
          raise Hyrax::SingleMembershipError, messages if messages.present?
        end

        # Add a work or collection as a member of a collection
        # @param collection_id [Valkyrie::ID] the id of the parent collection
        # @param new_member_id [Valkyrie::ID] the id of the new child collection or child work
        # @return [Hyrax::Resource] updated member resource
        def add_member_by_id(collection_id:, new_member_id:, user:)
          new_member = Hyrax.query_service.find_by(id: new_member_id)
          add_member(collection_id: collection_id, new_member: new_member, user: user)
        end

        # Add a work or collection as a member of a collection
        # @param collection_id [Valkyrie::ID] the id of the parent collection
        # @param new_member [Hyrax::Resource] the new child collection or child work
        # @return [Hyrax::Resource] updated member resource
        def add_member(collection_id:, new_member:, user:)
          message = Hyrax::MultipleMembershipChecker.new(item: new_member).check(collection_ids: [collection_id], include_current_members: true)
          raise Hyrax::SingleMembershipError, message if message.present?
          new_member.member_of_collection_ids += [collection_id] # only populate this direction
          new_member = Hyrax.persister.save(resource: new_member)
          publish_metadata_updated(new_member, user)
          new_member
        end

        # Remove collections and/or works from the members set of a collection
        # @param collection_id [Valkyrie::ID] the id of the parent collection
        # @param member_ids [Enumerable<Valkyrie::ID>] the ids of the child collections and/or child works to be removed
        # @return [Enumerable<Hyrax::Resource>] updated member resources
        def remove_members_by_ids(collection_id:, member_ids:, user:)
          members = Hyrax.query_service.find_many_by_ids(ids: member_ids)
          remove_members(collection_id: collection_id, members: members, user: user)
        end

        # Remove collections and/or works from the members set of a collection
        # @param collection_id [Valkyrie::ID] the id of the parent collection
        # @param members [Enumerable<Valkyrie::Resource>] the child collections and/or child works to be removed
        # @return [Enumerable<Hyrax::Resource>] updated member resources
        def remove_members(collection_id:, members:, user:)
          members.map { |member| remove_member(collection_id: collection_id, member: member, user: user) }
        end

        # Remove collections and/or works from the members set of a collection
        # @param collection_id [Valkyrie::ID] the id of the parent collection
        # @param member_id [Valkyrie::ID] the id of the child collection or child work to be removed
        # @return [Hyrax::Resource] updated member resource
        def remove_member_by_id(collection_id:, member_id:, user:)
          member = Hyrax.query_service.find_by(id: member_id)
          remove_member(collection_id: collection_id, member: member, user: user)
        end

        # Remove a collection or work from the members set of a collection, also removing the inverse relationship
        # @param collection_id [Valkyrie::ID] the id of the parent collection
        # @param member [Hyrax::Resource] the child collection or child work to be removed
        # @return [Hyrax::Resource] updated member resource
        def remove_member(collection_id:, member:, user:)
          return member unless member?(collection_id: collection_id, member: member)
          member.member_of_collection_ids.delete(collection_id)
          member = Hyrax.persister.save(resource: member)
          publish_metadata_updated(member, user)
          member
        end

        private

        def publish_metadata_updated(member, user)
          if member.collection?
            Hyrax.publisher.publish('collection.metadata.updated', collection: member, user: user)
          else
            Hyrax.publisher.publish('object.metadata.updated', object: member, user: user)
          end
        end
      end
    end
  end
end
