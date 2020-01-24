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
      # @param event [Dry::Event]
      def on_object_acl_updated(event)
        byebug
        return unless event[:result] == :success # do nothing on failure
        Hyrax.index_adapter.save(resource: event[:acl].resource)
      end
    end
  end
end
