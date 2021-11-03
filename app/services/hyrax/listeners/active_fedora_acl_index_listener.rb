# frozen_string_literal: true

module Hyrax
  module Listeners
    ##
    # Reindexes resources when their ACLs are updated
    #
    # Hyrax's `Ability` behavior depends on the index being up-to-date as
    # concerns-their read/write users/groups, and visibility.
    class ActiveFedoraAclIndexListener
      ##
      # Re-index the resource for the updated ACL.
      #
      # @param event [Dry::Event]
      def on_object_acl_updated(event)
        return if Hyrax.config.disable_wings
        return unless event[:result] == :success # do nothing on failure

        if Hyrax.metadata_adapter.is_a?(Wings::Valkyrie::MetadataAdapter)
          Wings::ActiveFedoraConverter.convert(resource: event[:acl].resource).update_index
        else
          Hyrax.logger.info('Skipping ActiveFedora object reindex because the Wings adapter is not in use.')
        end
      end
    end
  end
end
