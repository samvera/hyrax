# frozen_string_literal: true
module Hyrax
  module Collections
    module NestedCollectionPersistenceService
      # @api public
      #
      # Responsible for persisting the relationship between the parent and the child.
      # @see Hyrax::Collections::NestedCollectionQueryService
      #
      # @param parent [Hyrax::PcdmCollection | ::Collection]
      # @param child [Hyrax::PcdmCollection | ::Collection]
      # @param user [::User] current logged in user (defaults=nil for backward compatibility)
      # @note There is odd permission arrangement based on the NestedCollectionQueryService:
      #       You can nest the child within a parent if you can edit the parent and read the child.
      #       See https://wiki.lyrasis.org/display/samvera/Samvera+Tech+Call+2017-08-23 for tech discussion.
      def self.persist_nested_collection_for(parent:, child:, user: nil)
        child_resource = child.respond_to?(:valkyrie_resource) ? child.valkyrie_resource : child
        Hyrax::Collections::CollectionMemberService.add_member(collection_id: parent.id, new_member: child_resource, user: user)
      end

      # @param parent [Hyrax::PcdmCollection | ::Collection]
      # @param child [Hyrax::PcdmCollection | ::Collection]
      # @param user [::User] current logged in user (defaults=nil for backward compatibility)
      def self.remove_nested_relationship_for(parent:, child:, user: nil)
        child_resource = child.respond_to?(:valkyrie_resource) ? child.valkyrie_resource : child
        Hyrax::Collections::CollectionMemberService.remove_member(collection_id: parent.id, member: child_resource, user: user)
        true
      end
    end
  end
end
