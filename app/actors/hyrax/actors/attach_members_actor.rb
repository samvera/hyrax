# frozen_string_literal: true
module Hyrax
  module Actors
    ##
    # Attach or remove child works to/from this work. This decodes parameters
    # that follow the rails nested parameters conventions:
    # e.g.
    #   'work_members_attributes' => {
    #     '0' => { 'id' => '12312412'},
    #     '1' => { 'id' => '99981228', '_destroy' => 'true' }
    #   }
    #
    # The goal of this actor is to mutate the +#ordered_members+ with as few writes
    # as possible, because changing +#ordered_members+ is slow. This class only
    # writes changes, not the full ordered list.
    #
    # The +env+ for this actor may contain a +Valkyrie::Resource+ or an
    # +ActiveFedora::Base+ model, as required by the caller.
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
      # @param [Hyrax::Actors::Environment] env
      # @param [Hash<Hash>] attributes_collection a collection of members
      #
      # rubocop:disable Metrics/CyclomaticComplexity
      # Complexity in this method is incleased by dual AF/Valkyrie support
      # when removing AF, we should be able to reduce it substantially.
      def assign_nested_attributes_for_collection(env, attributes_collection)
        return true unless attributes_collection

        attributes         = extract_attributes(attributes_collection)
        cast_concern       = !env.curation_concern.is_a?(Valkyrie::Resource)
        resource           = cast_concern ? env.curation_concern.valkyrie_resource : env.curation_concern
        inserts, destroys  = split_inserts_and_destroys(attributes, resource)

        # short circuit to avoid casting unnecessarily
        return true if destroys.empty? && inserts.empty?
        # we fail silently if we can't insert the object; this is for legacy
        # compatibility
        return true unless check_permissions(ability: env.current_ability,
                                             inserts: inserts,
                                             destroys: destroys)

        update_members(resource: resource, inserts: inserts, destroys: destroys)

        return true unless cast_concern
        env.curation_concern = Hyrax.metadata_adapter
                                    .resource_factory
                                    .from_resource(resource: resource)
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      def extract_attributes(collection)
        collection
          .sort_by { |i, _| i.to_i }
          .map { |_, attributes| attributes }
      end

      def split_inserts_and_destroys(attributes, resource)
        current_member_ids = resource.member_ids.map(&:id)

        destroys = attributes.select do |col_hash|
          ActiveModel::Type::Boolean.new.cast(col_hash['_destroy'])
        end

        inserts  = (attributes - destroys).map { |h| h['id'] }.compact - current_member_ids
        destroys = destroys.map { |h| h['id'] }.compact & current_member_ids

        [inserts, destroys]
      end

      def update_members(resource:, inserts: [], destroys: [])
        resource.member_ids += inserts.map  { |id| Valkyrie::ID.new(id) }
        resource.member_ids -= destroys.map { |id| Valkyrie::ID.new(id) }
      end

      def check_permissions(ability:, inserts: [], **_opts)
        inserts.all? { |id| ability.can?(:edit, id) }
      end
    end
  end
end
