# frozen_string_literal: true
module Hyrax
  module Actors
    class ApplyOrderActor < AbstractActor
      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if update was successful
      def update(env)
        ordered_member_ids = env.attributes.delete(:ordered_member_ids)
        sync_members(env, ordered_member_ids) &&
          apply_order(env.curation_concern, ordered_member_ids) &&
          next_actor.update(env)
      end

      private

      def can_edit_both_works?(env, work)
        env.current_ability.can?(:edit, work) && env.current_ability.can?(:edit, env.curation_concern)
      end

      def sync_members(env, ordered_member_ids)
        return true if ordered_member_ids.nil?
        cleanup_ids_to_remove_from_curation_concern(env.curation_concern, ordered_member_ids)
        add_new_work_ids_not_already_in_curation_concern(env, ordered_member_ids)
        env.curation_concern.errors[:ordered_member_ids].empty?
      end

      # @todo Why is this not doing work.save?
      # @see Hyrax::Actors::AddToWorkActor for duplication
      def cleanup_ids_to_remove_from_curation_concern(curation_concern, ordered_member_ids)
        (curation_concern.ordered_member_ids - ordered_member_ids).each do |old_id|
          work = Hyrax.query_service.find_by_alternate_identifier(alternate_identifier: old_id, use_valkyrie: false)
          curation_concern.ordered_members.delete(work)
          curation_concern.members.delete(work)
        end
      end

      def add_new_work_ids_not_already_in_curation_concern(env, ordered_member_ids)
        (ordered_member_ids - env.curation_concern.ordered_member_ids).each do |work_id|
          work = Hyrax.query_service.find_by_alternate_identifier(alternate_identifier: work_id, use_valkyrie: false)
          if can_edit_both_works?(env, work)
            env.curation_concern.ordered_members << work
            env.curation_concern.save!
          else
            env.curation_concern.errors.add(:ordered_member_ids, "Works can only be related to each other if user has ability to edit both.")
          end
        end
      end

      def apply_order(curation_concern, new_order)
        return true unless new_order
        curation_concern.ordered_member_proxies.each_with_index do |proxy, index|
          unless new_order[index]
            proxy.prev.next = curation_concern.ordered_member_proxies.last.next
            break
          end
          proxy.proxy_for = Hyrax::Base.id_to_uri(new_order[index])
          proxy.target = nil
        end
        curation_concern.list_source.order_will_change!
        true
      end
    end
  end
end
