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

      # TODO: Methods requiring further investigation...
      #   #type_validator class method
      #   #ancestor?

      # TODO: Should these method NOT USED BY HYRAX be converted...
      #   #related_object_ids
      #   #related_objects

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
      # Gives the subset of #members that are PCDM objects
      # @return [Enumerable<ActiveFedora::Base> | Enumerable<Valkyrie::Resource>] an enumerable over the members
      #   that are PCDM objects
      # NOTE: A collection could be added to members, but for Hyrax collections are stored using member_of_collection_ids.
      #       As long as this rule holds, then members and ordered_members are equivalent to objects/child_objects.
      # TODO: Do we want to support members separate from child_objects (see NOTE)
      def child_objects(valkyrie: false)
        af_objects = Wings::ActiveFedoraConverter.new(resource: self).convert.objects
        return af_objects unless valkyrie
        af_objects.map(&:valkyrie_resource)
      end
      alias objects child_objects
      alias ordered_objects child_objects
      alias members child_objects
      alias ordered_members child_objects

      ##
      # Gives a subset of #member_ids, where all elements are PCDM objects.
      # @return [Enumerable<String> | Enumerable<Valkyrie::ID] the object ids
      # NOTE: A collection could be added to member_ids, but for Hyrax collections are stored using member_of_collection_ids.
      #       As long as this rule holds, then member_ids and ordered_member_ids are equivalent to object_ids/child_object_ids.
      # TODO: Do we want to support member_ids separate from child_objects (see NOTE)
      def child_object_ids(valkyrie: false)
        child_objects(valkyrie: valkyrie).map(&:id)
      end
      alias object_ids child_object_ids
      alias ordered_object_ids child_object_ids
      # alias member_ids child_object_ids # TODO: Cannot alias in this way because member_ids method is already defined thru the attribute definition.
      alias ordered_members_ids child_object_ids

      ##
      # @return [Enumerable<ActiveFedora::Base> | Enumerable<Valkyrie::Resource>] the collections the
      #    collection or object is a member of.
      # NOTE: For Hyrax, member_of_collection_ids is used to hold the parent collections.
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
      # TODO: This is using the member_of method which uses the members relationship.  That should
      #       never return any collections since they are stored using the member_of_collection
      #       relationship.  But this method is called in characterize_job.rb and collection_indexer.rb.
      #       It could be that these are no-ops because nothing is ever returned, but more exploration
      #       is needed to determine this.
      def in_collections(valkyrie: false)
        member_of(valkyrie: valkyrie).select(&:pcdm_collection?).to_a
      end

      # @return [Enumerable<String> | Enumerable<Valkyrie::ID] ids for collections the object is a member of
      # TODO: This is using the member_of method which uses the members relationship.  That should
      #       never return any collections since they are stored using the member_of_collection
      #       relationship.  But this method is called in base_actor.rb #destroy.
      #       It could be that these are no-ops because nothing is ever returned, but more exploration
      #       is needed to determine this.
      def in_collection_ids(valkyrie: false)
        in_collections(valkyrie: valkyrie).map(&:id)
      end

      ##
      # Any method not implemented is sent to the ActiveFedora version of the resource.
      def method_missing(name, *args, &block)
        # TODO: Remove the puts and this method when all methods are valkyrized
        af_object = Wings::ActiveFedoraConverter.new(resource: self).convert
        unless af_object.respond_to? name
          Rails.logger.warn "#{af_object.class} does not respond to method #{name}"
          super
        end
        Rails.logger.info "Calling through Method Missing with name: #{name}    args: #{args}   block_given? #{block_given?}"
        args.delete_if { |arg| arg.is_a?(Hash) && arg.key?(:valkyrie) }
        return af_object.send(name, args, block) if block_given?
        return af_object.send(name, args) if args.present?
        af_object.send(name)
      end

      def respond_to_missing?(_name, _include_private = false)
        true
      end
    end
  end
end
