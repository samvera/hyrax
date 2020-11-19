# frozen_string_literal: true
require 'wings/active_fedora_converter'

module Wings
  module Pcdm
    module PcdmValkyrieBehavior
      extend ActiveSupport::Concern

      included do
        attribute :member_of_collection_ids, ::Valkyrie::Types::Set.of(::Valkyrie::Types::ID)
        attribute :member_ids, ::Valkyrie::Types::Array.of(::Valkyrie::Types::ID).meta(ordered: true)
      end

      ##
      # @return [Enumerable<ActiveFedora::Base> | Enumerable<Valkyrie::Resource>] an enumerable over the parent collections
      def parent_collections(valkyrie: false)
        af_collections = parent_collection_ids.map { |id| ActiveFedora::Base.find(id) }
        return af_collections unless valkyrie
        af_collections.map(&:valkyrie_resource)
      end
      alias member_of_collections parent_collections

      ##
      # @return [Enumerable<String> | Enumerable<Valkyrie::ID] the parent collection ids
      def parent_collection_ids(valkyrie: false)
        return member_of_collection_ids if valkyrie
        member_of_collection_ids.map(&:id)
      end
      # alias member_of_collection_ids child_object_ids # TODO: Cannot alias in this way because member_of_collection_ids method is already defined thru the attribute definition.

      ##
      # @return [Enumerable<ActiveFedora::Base> | Enumerable<Valkyrie::Resource>] an enumerable over the child collections
      # @todo There is no guarantee to collection ordering until Hyrax is fully valkyrie-native, see issue 3784
      def child_collections(valkyrie: false)
        resources = Hyrax.custom_queries.find_child_collections(resource: self)
        return resources if valkyrie
        resources.map { |r| Wings::ActiveFedoraConverter.new(resource: r).convert }
      end
      alias collections child_collections
      alias member_collections child_collections
      alias ordered_collections child_collections

      ##
      # @return [Enumerable<String> | Enumerable<Valkyrie::ID] the child collection ids
      # @todo There is no guarantee to collection ordering until Hyrax is fully valkyrie-native, see issue 3784
      def child_collection_ids(valkyrie: false)
        child_collections(valkyrie: valkyrie).map(&:id)
      end
      alias collection_ids child_collection_ids
      alias member_collection_ids child_collection_ids
      alias ordered_collection_ids child_collection_ids

      ##
      # Gives the subset of #members that are PCDM objects
      # @return [Enumerable<ActiveFedora::Base> | Enumerable<Valkyrie::Resource>] an enumerable over the members
      #   that are PCDM objects
      # @note A collection could be added to members, but for Hyrax collections are stored using member_of_collection_ids.
      #       As long as this rule holds, then members and ordered_members are equivalent to objects/child_objects.
      # @todo Do we want to support members separate from child_objects (see NOTE)
      def child_objects(valkyrie: false)
        af_objects = Wings::ActiveFedoraConverter.new(resource: self).convert.objects
        return af_objects unless valkyrie
        af_objects.map(&:valkyrie_resource)
      end
      alias objects child_objects
      alias ordered_objects child_objects
      alias members child_objects
      alias ordered_members child_objects
      alias member_works child_objects

      ##
      # Gives a subset of #member_ids, where all elements are PCDM objects.
      # @return [Enumerable<String> | Enumerable<Valkyrie::ID] the object ids
      # @note A collection could be added to member_ids, but for Hyrax collections are stored using member_of_collection_ids.
      #       As long as this rule holds, then member_ids and ordered_member_ids are equivalent to object_ids/child_object_ids.
      # @todo Do we want to support member_ids separate from child_objects (see NOTE)
      def child_object_ids(valkyrie: false)
        child_objects(valkyrie: valkyrie).map(&:id)
      end
      alias object_ids child_object_ids
      alias ordered_object_ids child_object_ids
      # alias member_ids child_object_ids # TODO: Cannot alias in this way because member_ids method is already defined thru the attribute definition.
      alias ordered_members_ids child_object_ids
      alias member_work_ids child_object_ids

      ##
      # @return [Enumerable<ActiveFedora::Base> | Enumerable<Valkyrie::Resource>] the collections the
      #    collection or object is a member of.
      # @note For Hyrax, member_of_collection_ids is used to hold the parent collections.
      #       members is used to hold the child works and child filesets.  This method looks
      #       in solr for the members relationship and infers a member_of relationship through
      #       a solr query by looking for all parents that have self's id in their members list.
      def member_of(valkyrie: false)
        af_id = valkyrie ? id : id.id
        return [] if af_id.nil?
        af_parents = Wings::ActiveFedoraConverter.new(resource: self).convert.member_of
        return af_parents unless valkyrie
        af_parents.map(&:valkyrie_resource)
      end
      alias parent_objects member_of

      # @return [Enumerable<ActiveFedora::Base> | Enumerable<Valkyrie::Resource>] the collections the
      #   object is a member of.
      # @todo This is using the member_of method which uses the members relationship.  That should
      #       never return any collections since they are stored using the member_of_collection
      #       relationship.  But this method is called in characterize_job.rb and collection_indexer.rb.
      #       It could be that these are no-ops because nothing is ever returned, but more exploration
      #       is needed to determine this.
      def in_collections(valkyrie: false)
        member_of(valkyrie: valkyrie).select(&:pcdm_collection?).to_a
      end

      # @return [Enumerable<String> | Enumerable<Valkyrie::ID] ids for collections the object is a member of
      # @todo This is using the member_of method which uses the members relationship.  That should
      #       never return any collections since they are stored using the member_of_collection
      #       relationship.  But this method is called in base_actor.rb #destroy.
      #       It could be that these are no-ops because nothing is ever returned, but more exploration
      #       is needed to determine this.
      def in_collection_ids(valkyrie: false)
        in_collections(valkyrie: valkyrie).map(&:id)
      end

      ##
      # @return [Boolean] whether this instance is an audio.
      def audio?
        af_object = Wings::ActiveFedoraConverter.new(resource: self).convert
        af_object.audio?
      end

      # @param valkyrie [Boolean] Should the returned ids be for Valkyrie or AF objects?
      # @return [Enumerable<Hydra::Works::Work>] The works this work is contained in
      # @note This method avoids using the Hydra::Works version of parent_works because of Issue #361
      def parent_works(valkyrie: false)
        af_child = Wings::ActiveFedoraConverter.new(resource: self).convert
        af_parents = af_child.member_of_works
        return af_parents unless valkyrie
        af_parents.map(&:valkyrie_resource)
      end

      # @param valkyrie [Boolean] Should the returned ids be for Valkyrie or AF objects?
      # @return [Enumerable<String> | Enumerable<Valkyrie::ID>] The ids of the works this work is contained in
      def parent_work_ids(valkyrie: false)
        parent_works(valkyrie: valkyrie).map(&:id)
      end
    end
  end
end
