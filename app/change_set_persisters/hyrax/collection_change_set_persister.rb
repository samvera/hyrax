# frozen_string_literals: true

module Hyrax
  class CollectionChangeSetPersister < ChangeSetPersister
    after_save :process_member_changes

    def process_member_changes(change_set:, resource:)
      case change_set.members
      when 'remove'
        remove_members_from_collection(change_set: change_set, resource: resource)
      when 'move'
        move_members_between_collections(change_set: change_set, resource: resource)
      else
        add_members_to_collection(change_set: change_set, resource: resource)
      end
    end

    private

      def remove_members_from_collection(change_set:, resource:)
        Array(change_set.batch).each do |member_id|
          member = find_resource(member_id)
          member.member_of_collection_ids.delete resource.id
          persister.save(resource: member)
        end
      end

      def add_members_to_collection(change_set:, resource:)
        Array(change_set.batch).each do |member_id|
          member = find_resource(member_id)
          member.member_of_collection_ids << resource.id
          persister.save(resource: member)
        end
      end

      def move_members_between_collections(change_set:, resource:)
        destination_collection = find_resource(change_set.destination_collection_id)
        remove_members_from_collection(change_set: change_set, resource: resource)
        add_members_to_collection(change_set: change_set, resource: destination_collection)
      end

      def find_resource(id)
        query_service.find_by(id: Valkyrie::ID.new(id.to_s))
      end

      def query_service
        Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
      end
  end
end
