require 'wings/value_mapper'
require 'wings/active_fedora_converter'

module Wings
  module Pcdm
    module PcdmValkyrieBehavior
      extend ActiveSupport::Concern

      included do
        attribute :member_of_collection_ids, ::Valkyrie::Types::Set.of(::Valkyrie::Types::ID)
        attribute :member_ids, ::Valkyrie::Types::Array.of(::Valkyrie::Types::ID).meta(ordered: true)
        # TODO: get/set via members and ordered_members
        #   * get objs - For both, this is the same as #objects. Because the Array in Valkyrie is ordered, everything will be ordered
        #   * get ids - always returns valkyrie ids -- can't define a method for member_ids(valkyrie: false) which would return af ids
        #   * set - In AF, members and ordered_members are enumerable and can be set using operators << and +=.
        #           Since member_ids is all that keeps these in wings, how can we do that here?
      end

      # Add member objects by adding this collection to the objects' member_of_collection association.
      # @param [Enumerable<String> | Enumerable<Valkyrie::ID] the ids of the new child collections and works collection ids
      def add_collections_and_works(new_member_ids, valkyrie: false)
        ### TODO: Change to do this through Valkyrie.  Right now using existing AF method to get multi-membership check.
        af_self = Wings::ActiveFedoraConverter.new(resource: self).convert
        af_ids = valkyrie ? convert_to_active_fedora_ids(new_member_ids) : new_member_ids
        af_self.add_member_objects(af_ids)
      end
      alias add_member_objects add_collections_and_works

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

      ##
      # @return [Enumerable<ActiveFedora::Base> | Enumerable<Valkyrie::Resource>] an enumerable over the children of this collection
      def child_collections_and_works(valkyrie: false)
        af_collections_and_works = ActiveFedora::Base.where("member_of_collection_ids_ssim:#{id.id}")
        return af_collections_and_works unless valkyrie
        af_collections_and_works.map(&:valkyrie_resource)
      end
      alias member_objects child_collections_and_works

      ##
      # Gives the subset of #members that are PCDM objects
      # @return [Enumerable<ActiveFedora::Base> | Enumerable<Valkyrie::Resource>] an enumerable over the members
      #   that are PCDM objects
      def objects(valkyrie: false)
        af_objects = Wings::ActiveFedoraConverter.new(resource: self).convert.objects
        return af_objects unless valkyrie
        af_objects.map(&:valkyrie_resource)
      end
      alias members objects
      alias ordered_members objects

      ##
      # Gives a subset of #member_ids, where all elements are PCDM objects.
      # @return [Enumerable<String> | Enumerable<Valkyrie::ID] the object ids
      def object_ids(valkyrie: false)
        objects(valkyrie: valkyrie).map(&:id)
      end

      def convert_to_active_fedora_ids(valkyrie_ids)
        metadata_adapter = Hyrax.config.valkyrie_metadata_adapter
        resources = valkyrie_ids.map { |id| metadata_adapter.query_service.find_by(id: id) }
        resources.map { |resource| resource.id.id } # TODO: What if id.id is empty?
      end
    end
  end
end
