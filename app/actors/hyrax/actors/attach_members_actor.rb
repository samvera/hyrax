module Hyrax
  module Actors
    # Attach or remove child works to/from this work. This decodes parameters
    # that follow the rails nested parameters conventions:
    # e.g.
    #   'work_members_attributes' => {
    #     '0' => { 'id' = '12312412'},
    #     '1' => { 'id' = '99981228', '_destroy' => 'true' }
    #   }
    #
    # The goal of this actor is to mutate the ordered_members with as few writes
    # as possible, because changing ordered_members is slow. This class only
    # writes changes, not the full ordered list.
    class AttachMembersActor < Hyrax::Actors::AbstractActor
      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if update was successful
      def update(env)
        attributes_collection = env.attributes.delete(:work_members_attributes)
        assign_nested_attributes_for_collection(env, attributes_collection) &&
          next_actor.update(env)
      end

      private

        # Attaches any unattached members.  Deletes those that are marked _delete
        # @param [Hash<Hash>] a collection of members
        def assign_nested_attributes_for_collection(env, attributes_collection)
          return true unless attributes_collection
          attributes_collection = attributes_collection.sort_by { |i, _| i.to_i }.map { |_, attributes| attributes }
          # checking for existing works to avoid rewriting/loading works that are
          # already attached
          existing_works = env.curation_concern.member_ids
          attributes_collection.each do |attributes|
            next if attributes['id'].blank?
            if existing_works.include?(attributes['id'])
              remove(env.curation_concern, attributes['id']) if has_destroy_flag?(attributes)
            else
              add(env, attributes['id'])
            end
          end
        end

        # Adds the item to the ordered members so that it displays in the items
        # along side the FileSets on the show page
        def add(env, id)
          return unless env.current_ability.can?(:edit, id)
          env.curation_concern.member_ids << id
        end

        # Remove the object from the members set and the ordered members list
        def remove(curation_concern, id)
          curation_concern.member_ids.delete(id)
        end

        # Determines if a hash contains a truthy _destroy key.
        # rubocop:disable Style/PredicateName
        def has_destroy_flag?(hash)
          ActiveFedora::Type::Boolean.new.cast(hash['_destroy'])
        end
        # rubocop:enable Style/PredicateName

        def query_service
          Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
        end
    end
  end
end
