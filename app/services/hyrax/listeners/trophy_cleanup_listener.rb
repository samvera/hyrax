# frozen_string_literal: true

module Hyrax
  module Listeners
    ##
    # Listens for object deleted events and cleans up associated members
    class TrophyCleanupListener
      # Called when 'object.deleted' event is published
      # @param [Dry::Events::Event] event
      # @return [void]
      def on_object_deleted(event)
        object_id = event[:object]&.id || event[:id]
        Trophy.where(work_id: object_id).destroy_all
      rescue StandardError => err
        Hyrax.logger.warn "Failed to delete trophies for #{event[:id]}. " \
                          'These trophies might be orphaned.' \
                          "\n\t#{err.message}"
      end
    end
  end
end
