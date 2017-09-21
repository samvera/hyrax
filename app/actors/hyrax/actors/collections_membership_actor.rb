module Hyrax
  module Actors
    # Adds membership to and removes membership from collections
    class CollectionsMembershipActor < AbstractActor
      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if create was successful
      def create(env)
        collection_ids = env.attributes.delete(:member_of_collection_ids)
        extract_collection_id(env, collection_ids)
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
          multiple_memberships = Hyrax::MultipleMembershipChecker.new(item: env.curation_concern).check(collection_ids: collection_ids)
          if multiple_memberships
            env.curation_concern.errors.add(:collections, multiple_memberships)
            return false
          end
          # grab/save collections this user has no edit access to
          other_collections = collections_without_edit_access(env)
          env.curation_concern.member_of_collections = ::Collection.find(collection_ids)
          env.curation_concern.member_of_collections.concat other_collections
        end

        def collections_without_edit_access(env)
          env.curation_concern.member_of_collections.select { |coll| env.current_ability.cannot?(:edit, coll) }
        end

        # Given an array of collection_ids when it is size:
        # * 0 do not set `env.attributes[:collection_id]`
        # * 1 set `env.attributes[:collection_id]` to the one and only one collection
        # * 2 do not set `env.attributes[:collection_id]`
        #
        # Later on in apply_permission_template_actor.rb, `env.attributes[:collection_id]` will be used to apply the
        # permissions of the collection to the created work.  With one and only one collection, the work is seen as
        # being created directly in that collection.
        def extract_collection_id(env, collection_ids)
          return unless collection_ids && collection_ids.size == 1
          env.attributes[:collection_id] = collection_ids.first
        end
    end
  end
end
