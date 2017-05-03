# frozen_string_literal: true

module Hyrax
  module Actors
    # Adds membership to and removes membership from collections
    class CollectionsMembershipActor < AbstractActor
      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if create was successful
      def create(env)
        collection_ids = env.attributes.delete(:member_of_collection_ids)
        assign_collections(env, collection_ids) && next_actor.create(env)
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if update was successful
      def update(env)
        collection_ids = env.attributes.delete(:member_of_collection_ids)
        assign_collections(env, collection_ids) && next_actor.update(env)
      end

      private

        # Maps from collection ids to collection objects
        def assign_collections(env, collection_ids)
          return true unless collection_ids
          # grab/save collections this user has no edit access to
          other_collections = collections_without_edit_access(env)
          env.curation_concern.member_of_collections = ::Collection.find(collection_ids)
          env.curation_concern.member_of_collections.concat other_collections
        end

        def collections_without_edit_access(env)
          env.curation_concern.member_of_collections.select { |coll| env.current_ability.cannot?(:edit, coll) }
        end
    end
  end
end
