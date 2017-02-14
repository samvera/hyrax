module Hyrax
  module Actors
    class AddAsMemberOfCollectionsActor < AbstractActor
      def create(attributes)
        collection_ids = attributes.delete(:member_of_collection_ids)
        add_to_collections(collection_ids) && next_actor.create(attributes)
      end

      def update(attributes)
        collection_ids = attributes.delete(:member_of_collection_ids)
        add_to_collections(collection_ids) && next_actor.update(attributes)
      end

      private

        # Maps from collection ids to collection objects
        def add_to_collections(collection_ids)
          return true unless collection_ids
          # grab/save collections this user has no edit access to
          other_collections = curation_concern.member_of_collections.select { |coll| ability.cannot?(:edit, coll) }
          curation_concern.member_of_collections = ::Collection.find(collection_ids)
          curation_concern.member_of_collections.concat other_collections
        end
    end
  end
end
