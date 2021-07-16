# frozen_string_literal: true
module Hyrax
  module Collections
    ##
    # Retrieves collection members
    class CollectionMemberService < Hyrax::SearchService
      ##
      # @param scope [#repository] Typically a controller object which responds to :repository
      # @param [::Collection] collection
      # @param [ActionController::Parameters] params the query params
      # @param [ActionController::Parameters] user_params
      # @param [::Ability] current_ability
      # @param [Class] search_builder_class a {::SearchBuilder}
      def initialize(scope:, collection:, params:, user_params: nil, current_ability: nil, search_builder_class: Hyrax::CollectionMemberSearchBuilder) # rubocop:disable Metrics/ParameterLists
        super(
          config: scope.blacklight_config,
          user_params: user_params || params,
          collection: collection,
          scope: scope,
          current_ability: current_ability || scope.current_ability,
          search_builder_class: search_builder_class
        )
      end

      ##
      # @api public
      #
      # Collections which are members of the given collection
      #
      # @return [Blacklight::Solr::Response] (up to 50 solr documents)
      def available_member_subcollections
        response, _docs = search_results do |builder|
          # To differentiate current page for works vs subcollections, we have to use a sub_collection_page
          # param. Map this to the page param before querying for subcollections, if it's present
          builder.page(user_params[:sub_collection_page])
          builder.search_includes_models = :collections
          builder
        end
        response
      end

      ##
      # @api public
      #
      # Works which are members of the given collection
      #
      # @return [Blacklight::Solr::Response]
      def available_member_works
        response, _docs = search_results do |builder|
          builder.search_includes_models = :works
          builder
        end
        response
      end

      ##
      # @api public
      #
      # Work ids of the works which are members of the given collection
      #
      # @return [Blacklight::Solr::Response]
      def available_member_work_ids
        response, _docs = search_results do |builder|
          builder.search_includes_models = :works
          builder.merge(fl: 'id')
          builder
        end
        response
      end

      class << self
        # Check if a work or collection is already a member of a collection
        # @param collection [Hyrax::PcdmCollection] the collection
        # @param member [Hyrax::Resource] the child collection and/or child work to check
        # @return [Boolean] true if already in the member set; otherwise, false
        def member?(collection:, member:)
          member.member_of_collection_ids.include? collection.id
        end

        # Add works and/or collections as members of a collection
        # @param collection [Hyrax::PcdmCollection] the collection
        # @param new_member_ids [Enumerable<Valkyrie::ID>] the ids of the new child collections and/or child works
        # @return [Enumerable<Hyrax::Resource>] updated member resources
        def add_members_by_ids(collection:, new_member_ids:, user:)
          new_members = Hyrax.query_service.find_many_by_ids(ids: new_member_ids)
          add_members(collection: collection, new_members: new_members, user: user)
        end

        # Add works and/or collections as members of a collection
        # @param collection [Hyrax::PcdmCollection] the collection
        # @param new_members [Enumerable<Hyrax::Resource>] the new child collections and/or child works
        # @return [Enumerable<Hyrax::Resource>] updated member resources
        def add_members(collection:, new_members:, user:)
          new_members.map { |new_member| add_member(collection: collection, new_member: new_member, user: user) }
        end

        # Add a work or collection as a member of a collection
        # @param collection [Hyrax::PcdmCollection] the collection
        # @param new_member_id [Valkyrie::ID] the id of the new child collection or child work
        # @return [Hyrax::Resource] updated member resource
        def add_member_by_id(collection:, new_member_id:, user:)
          new_member = Hyrax.query_service.find_by(id: new_member_id)
          add_member(collection: collection, new_member: new_member, user: user)
        end

        # Add a work or collection as a member of a collection
        # @param collection [Hyrax::PcdmCollection] the collection
        # @param new_member [Hyrax::Resource] the new child collection or child work
        # @return [Hyrax::Resource] updated member resource
        def add_member(collection:, new_member:, user:)
          message = Hyrax::MultipleMembershipChecker.new(item: new_member).check(collection_ids: collection.id, include_current_members: true)
          if message
            new_member.errors.add(:collections, message)
          else
            new_member.member_of_collection_ids += [collection.id] # only populate this direction
            new_member = Hyrax.persister.save(resource: new_member)
            Hyrax.publisher.publish('object.metadata.updated', object: new_member, user: user)
          end
          new_member
        end

        # Remove collections and/or works from the members set of a collection
        # @param collection [Hyrax::PcdmCollection] the collection
        # @param member_ids [Enumerable<Valkyrie::ID>] the ids of the child collections and/or child works to be removed
        # @return [Enumerable<Hyrax::Resource>] updated member resources
        def remove_members_by_ids(collection:, member_ids:, user:)
          members = Hyrax.query_service.find_many_by_ids(ids: member_ids)
          remove_members(collection: collection, members: members, user: user)
        end

        # Remove collections and/or works from the members set of a collection
        # @param collection [Hyrax::PcdmCollection] the collection
        # @param members [Enumerable<Valkyrie::Resource>] the child collections and/or child works to be removed
        # @return [Enumerable<Hyrax::Resource>] updated member resources
        def remove_members(collection:, members:, user:)
          members.map { |member| remove_member(collection: collection, member: member, user: user) }
        end

        # Remove collections and/or works from the members set of a collection
        # @param collection [Hyrax::PcdmCollection] the collection
        # @param member_id [Valkyrie::ID] the id of the child collection or child work to be removed
        # @return [Hyrax::Resource] updated member resource
        def remove_member_by_id(collection:, member_id:, user:)
          member = Hyrax.query_service.find_by(id: member_id)
          remove_member(collection: collection, member: member, user: user)
        end

        # Remove a collection or work from the members set of a collection, also removing the inverse relationship
        # @param collection [Hyrax::PcdmCollection] the collection
        # @param member [Hyrax::Resource] the child collection or child work to be removed
        # @return [Hyrax::Resource] updated member resource
        def remove_member(collection:, member:, user:)
          return member unless member?(collection: collection, member: member)
          member.member_of_collection_ids -= [collection.id]
          member = Hyrax.persister.save(resource: member)
          Hyrax.publisher.publish('object.metadata.updated', object: member, user: user)
          member
        end
      end
    end
  end
end
