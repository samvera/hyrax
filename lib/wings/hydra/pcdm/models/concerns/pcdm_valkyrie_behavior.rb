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
    end
  end
end
