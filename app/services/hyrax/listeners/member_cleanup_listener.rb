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
        return unless event.payload.key?(:object) # legacy callback
        return if event[:object].is_a?(ActiveFedora::Base) # handled by legacy code

        Hyrax.custom_queries.find_child_filesets(resource: event[:object]).each do |file_set|
          begin
            Hyrax.persister.delete(resource: file_set)
            Hyrax.publisher
                 .publish('object.deleted', object: file_set, id: file_set.id, user: user)
          rescue StandardError # we don't uncaught errors looping filesets
            Hyrax.logger.warn "Failed to delete #{file_set.class}:#{file_set.id} " \
                              "during cleanup for resource: #{event[:object]}. " \
                              'This member may now be orphaned.'
          end
        end
      end

      # Called when 'collection.deleted' event is published
      # @param [Dry::Events::Event] event
      # @return [void]
      def on_collection_deleted(event)
        return unless event.payload.key?(:collection) # legacy callback
        return if event[:collection].is_a?(ActiveFedora::Base) # handled by legacy code

        Hyrax.custom_queries.find_members_of(collection: event[:collection]).each do |resource|
          begin
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
end
