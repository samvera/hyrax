# frozen_string_literal: true

module Hyrax
  module Listeners
    ##
    # Reindexes resources when their ACLs are updated.
    #
    # Hyrax's `Ability` behavior depends on the index being up-to-date as
    # concerns-their read/write users/groups, and visibility.
    class AclIndexListener
      ##
      # Re-index the resource for the updated ACL.
      #
      # Called when 'object.acl.updated' event is published
      # @param [Dry::Events::Event] event
      # @return [void]
      def on_object_acl_updated(event)
        return unless event[:result] == :success # do nothing on failure
        Hyrax.index_adapter.save(resource: event[:acl].resource)
      end

      ##
      # Deletes the resource for the ACL from the index.
      #
      # Called when 'object.acl.deleted' event is published
      # @param [Dry::Events::Event] event
      # @return [void]
      def on_object_acl_deleted(event)
        Hyrax.index_adapter.delete(resource: event[:acl])
      end
    end
  end
end
