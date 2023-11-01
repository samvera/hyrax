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
      def on_collection_deleted(event); end
    end
  end
end
