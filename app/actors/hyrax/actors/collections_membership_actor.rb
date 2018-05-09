module Hyrax
  module Actors
    # Adds membership to and removes membership from collections.
    # This decodes parameters that follow the rails nested parameters conventions:
    #
    # @example a collections attribute hash
    #   'member_of_collections_attributes' => {
    #     '0' => { 'id' = '12312412'},
    #     '1' => { 'id' = '99981228', '_destroy' => 'true' }
    #   }
    #
    class CollectionsMembershipActor < AbstractActor
      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if create was successful
      def create(env)
        extract_collection_id(env)
        assign_nested_attributes_for_collection(env) && next_actor.create(env)
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if update was successful
      def update(env)
        assign_nested_attributes_for_collection(env) && next_actor.update(env)
      end

      private

        ##
        # Attaches any unattached members.  Deletes those that are marked _delete
        #
        # @param env [Hyrax::Actors::Enviornment]
        # @return [Boolean]
        #
        # rubocop:disable Metrics/MethodLength
        # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        def assign_nested_attributes_for_collection(env)
          attributes_collection = env.attributes.delete(:member_of_collections_attributes)

          return assign_for_collection_ids(env) unless attributes_collection

          emit_deprecation if env.attributes.delete(:member_of_collection_ids)

          return false unless
            valid_membership?(env, collection_ids: attributes_collection.map { |_, attributes| attributes['id'] })

          attributes_collection = attributes_collection.sort_by { |i, _| i.to_i }.map { |_, attributes| attributes }
          # checking for existing works to avoid rewriting/loading works that are already attached
          existing_collections = env.curation_concern.member_of_collection_ids
          attributes_collection.each do |attributes|
            next if attributes['id'].blank?
            if existing_collections.include?(attributes['id'])
              remove(env.curation_concern, attributes['id']) if has_destroy_flag?(attributes)
            else
              add(env, attributes['id'])
            end
          end

          true
        end
        # rubocop:enable Metrics/MethodLength
        # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

        ##
        # @deprecated supports old :member_of_collection_ids arguments
        def emit_deprecation
          Deprecation.warn(self, ':member_of_collections_attributes and :member_of_collection_ids were both ' \
                                 ' passed. :member_of_collection_ids is ignored when both are passed and is ' \
                                 'deprecated for removal in Hyrax 3.0.')
        end

        ##
        # @deprecated supports old :member_of_collection_ids arguments
        def assign_for_collection_ids(env)
          collection_ids = env.attributes.delete(:member_of_collection_ids)

          return false unless valid_membership?(env, collection_ids: collection_ids)

          if collection_ids
            Deprecation.warn(self, ':member_of_collection_ids has been deprecated for removal in Hyrax 3.0. ' \
                                   'use :member_of_collections_attributes instead.')

            collection_ids = [] if collection_ids.empty?
            other_collections = collections_without_edit_access(env)

            collections = ::Collection.find(collection_ids)
            raise "Tried to assign collections with ids: #{collection_ids}, but none were found" unless
              collections

            env.curation_concern.member_of_collections = collections
            env.curation_concern.member_of_collections.concat(other_collections)
          end

          true
        end

        ##
        # @deprecated supports old :member_of_collection_ids arguments
        def collections_without_edit_access(env)
          env.curation_concern.member_of_collections.select { |coll| env.current_ability.cannot?(:edit, coll) }
        end

        # Adds the item to the ordered members so that it displays in the items
        # along side the FileSets on the show page
        def add(env, id)
          collection = Collection.find(id)
          collection.reindex_extent = Hyrax::Adapters::NestingIndexAdapter::LIMITED_REINDEX

          return unless env.current_ability.can?(:deposit, collection)
          env.curation_concern.member_of_collections << collection
        end

        # Remove the object from the members set and the ordered members list
        def remove(curation_concern, id)
          collection = Collection.find(id)
          curation_concern.member_of_collections.delete(collection)
        end

        # Determines if a hash contains a truthy _destroy key.
        # rubocop:disable Naming/PredicateName
        def has_destroy_flag?(hash)
          ActiveFedora::Type::Boolean.new.cast(hash['_destroy'])
        end
        # rubocop:enable Naming/PredicateName

        # Extact a singleton collection id from the collection attributes and save it in env.  Later in the actor stack,
        # in apply_permission_template_actor.rb, `env.attributes[:collection_id]` will be used to apply the
        # permissions of the collection to the created work.  With one and only one collection, the work is seen as
        # being created directly in that collection.  The permissions will not be applied to the work if the collection
        # type is configured not to allow that or if the work is being created in more than one collection.
        #
        # @param env [Hyrax::Actors::Enviornment]
        #
        # Given an array of collection_attributes when it is size:
        # * 0 do not set `env.attributes[:collection_id]`
        # * 1 set `env.attributes[:collection_id]` to the one and only one collection
        # * 2+ do not set `env.attributes[:collection_id]`
        #
        # NOTE: Only called from create.  All collections are being added as parents of a work.  None are being removed.
        def extract_collection_id(env)
          attributes_collection =
            env.attributes.fetch(:member_of_collections_attributes) { nil }

          if attributes_collection
            # Determine if the work is being created in one and only one collection.
            return unless attributes_collection && attributes_collection.size == 1

            # Extract the collection id from attributes_collection,
            collection_id = attributes_collection.first.second['id']
          else
            collection_ids = env.attributes.fetch(:member_of_collection_ids) { [] }
            return unless collection_ids.size == 1
            collection_id = collection_ids.first
          end

          # Do not apply permissions to work if collection type is configured not to
          collection = ::Collection.find(collection_id)
          return unless collection.share_applies_to_new_works?

          # Save the collection id in env for use in apply_permission_template_actor
          env.attributes[:collection_id] = collection_id
        end

        def valid_membership?(env, collection_ids:)
          multiple_memberships = Hyrax::MultipleMembershipChecker.new(item: env.curation_concern).check(collection_ids: collection_ids)
          if multiple_memberships
            env.curation_concern.errors.add(:collections, multiple_memberships)
            return false
          end
          true
        end
    end
  end
end
