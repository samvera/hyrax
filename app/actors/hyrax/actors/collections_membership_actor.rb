module Hyrax
  module Actors
    # Adds membership to and removes membership from collections.
    # This decodes parameters that follow the rails nested parameters conventions:
    # e.g.
    #   'member_of_collections_attributes' => {
    #     '0' => { 'id' = '12312412'},
    #     '1' => { 'id' = '99981228', '_destroy' => 'true' }
    #   }
    #
    class CollectionsMembershipActor < AbstractActor
      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if create was successful
      def create(env)
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
        # @param [Hash<Hash>] a collection of members
        # rubocop:disable Metrics/MethodLength
        def assign_nested_attributes_for_collection(env)
          attributes_collection ||= env.attributes.delete(:member_of_collections_attributes)
          return assign_for_collection_ids(env) unless attributes_collection

          emit_deprecation if env.attributes.delete(:member_of_collection_ids)

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

          if collection_ids
            Deprecation.warn(self, ':member_of_collection_ids has been deprecated for removal in Hyrax 3.0. ' \
                                   'use :member_of_collections_attributes instead.')

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
          member = Collection.find(id)
          return unless env.current_ability.can?(:edit, member)
          env.curation_concern.member_of_collections << member
        end

        # Remove the object from the members set and the ordered members list
        def remove(curation_concern, id)
          member = Collection.find(id)
          curation_concern.member_of_collections.delete(member)
        end

        # Determines if a hash contains a truthy _destroy key.
        # rubocop:disable Naming/PredicateName
        def has_destroy_flag?(hash)
          ActiveFedora::Type::Boolean.new.cast(hash['_destroy'])
        end
      # rubocop:enable Naming/PredicateName
    end
  end
end
