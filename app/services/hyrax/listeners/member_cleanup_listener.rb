# frozen_string_literal: true

module Hyrax
  module Listeners
    ##
    # Listens for resource deleted events and cleans up associated members
    class MemberCleanupListener
      # Called when 'object.deleted' event is published
      # @param [Dry::Events::Event] event
      # @return [void]
      def on_object_deleted(event)
        event = event.to_h
        return unless event[:object]

        object = event[:object]
        user = event[:user]
        return unless object.is_a?(Hyrax::Work)

        Hyrax.query_service.find_parents(resource: object).each do |parent|
          parent.member_ids -= [object.id]
          Hyrax.persister.save(resource: parent)
          Hyrax.index_adapter.save(resource: parent)
          Hyrax.publisher.publish('object.membership.updated', object: parent, user: user)
        end
      end

      # Called when 'collection.deleted' event is published
      # @param [Dry::Events::Event] event
      # @return [void]
      def on_collection_deleted(event); end
    end
  end
end
