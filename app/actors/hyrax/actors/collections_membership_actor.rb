# frozen_string_literal: true
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
      # rubocop:disable Metrics/PerceivedComplexity
      # rubocop:disable Metrics/CyclomaticComplexity
      def assign_nested_attributes_for_collection(env)
        attributes_collection = env.attributes.delete(:member_of_collections_attributes)
        return true unless attributes_collection

        return false unless
          valid_membership?(env, collection_ids: attributes_collection.map { |_, attributes| attributes['id'] })

        attributes_collection = attributes_collection.sort_by { |i, _| i.to_i }.map { |_, attributes| attributes }
        # checking for existing works to avoid rewriting/loading works that are already attached
        existing_collections = env.curation_concern.member_of_collection_ids
        boolean_type_caster = ActiveModel::Type::Boolean.new
        attributes_collection.each do |attributes|
          next if attributes['id'].blank?
          if boolean_type_caster.cast(attributes['_destroy'])
            # Likely someone in the UI sought to add the collection, then
            # changed their mind and checked the "delete" checkbox and posted
            # their update.
            next unless existing_collections.include?(attributes['id'])
            remove(env.curation_concern, attributes['id'])
          else
            # Let's not try to add an item already
            next if existing_collections.include?(attributes['id'])
            add(env, attributes['id'])
          end
        end
        true
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/PerceivedComplexity
      # rubocop:enable Metrics/CyclomaticComplexity

      # Adds the item to the ordered members so that it displays in the items
      # along side the FileSets on the show page
      def add(env, id)
        collection = Hyrax.config.collection_class.find(id)

        return unless env.current_ability.can?(:deposit, collection)
        env.curation_concern.member_of_collections << collection
      end

      # Remove the object from the members set and the ordered members list
      def remove(curation_concern, id)
        collection = Hyrax.config.collection_class.find(id)
        curation_concern.member_of_collections.delete(collection)
      end

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

        # Determine if the work is being created in one and only one collection.
        return unless attributes_collection && attributes_collection.size == 1

        # Extract the collection id from attributes_collection,
        collection_id = attributes_collection.first.second['id']

        # Do not apply permissions to work if collection type is configured not to
        collection = Hyrax.config.collection_class.find(collection_id)
        return unless Hyrax::CollectionType.for(collection: collection).share_applies_to_new_works?

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
