# frozen_string_literal: true

module Hyrax
  module Listeners
    ##
    # Listens for resource deleted events and cleans up associated members
    class MemberCleanupListener
      # Called when 'object.deleted' event is published
      # @param [Dry::Events::Event] event
      # @return [void]
      def on_object_deleted(event); end

      # Called when 'collection.deleted' event is published
      # @param [Dry::Events::Event] event
      # @return [void]
      def on_collection_deleted(event)
        return unless event.payload.key?(:collection) # legacy callback
        return if event[:collection].is_a?(ActiveFedora::Base) # handled by legacy code

        Hyrax.custom_queries.find_members_of(collection: event[:collection]).each do |resource|
          resource.member_of_collection_ids -= [event[:collection].id]
          Hyrax.persister.save(resource: resource)
          Hyrax.publisher
               .publish('collection.membership.updated', collection: event[:collection], user: event[:user])
        rescue StandardError
          Hyrax.logger.warn "Failed to remove collection reference from #{work.class}:#{work.id} " \
                            "during cleanup for collection: #{event[:collection]}. "
        end
      end
    end
  end
end
