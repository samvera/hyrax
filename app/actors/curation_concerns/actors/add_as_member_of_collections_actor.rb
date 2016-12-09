module CurationConcerns
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
          curation_concern.member_of_collections = collection_ids.map { |id| ::Collection.find(id) }
        end
    end
  end
end
