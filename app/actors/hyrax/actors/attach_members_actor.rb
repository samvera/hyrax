module Hyrax
  module Actors
    # Attach or remove child works to/from this work. This decodes parameters
    # that follow the rails nested parameters conventions:
    # e.g.
    #   'work_members_attributes' => {
    #     '0' => { 'id' => '12312412'},
    #     '1' => { 'id' => '99981228', '_destroy' => 'true' }
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

          attributes_collection = attributes_collection
                                  .sort_by { |i, _| i.to_i }
                                  .map { |_, attributes| attributes }

          resource           = env.curation_concern.valkyrie_resource
          current_member_ids = resource.member_ids.map(&:id)
          inserts, destroys  = split_inserts_and_destroys(attributes_collection, current_member_ids)

          return true if destroys.empty? && inserts.empty?
          # we fail silently if we can't insert the object; this is for legacy
          # compatibility
          return true unless inserts.all? { |id| env.current_ability.can?(:edit, id) }

          resource.member_ids += inserts.map  { |id| Valkyrie::ID.new(id) }
          resource.member_ids -= destroys.map { |id| Valkyrie::ID.new(id) }

          env.curation_concern = Hyrax.metadata_adapter
                                      .resource_factory
                                      .from_resource(resource: resource)
        end

        def split_inserts_and_destroys(attributes_collection, current_member_ids)
          destroys = attributes_collection.select do |col_hash|
            ActiveModel::Type::Boolean.new.cast(col_hash['_destroy'])
          end

          inserts  = (attributes_collection - destroys).map { |h| h['id'] }.compact - current_member_ids
          destroys = destroys.map { |h| h['id'] }.compact & current_member_ids

          [inserts, destroys]
        end
    end
  end
end
