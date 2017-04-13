module Hyrax
  module Actors
    class AddToWorkActor < AbstractActor
      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if create was successful
      def create(env)
        work_ids = env.attributes.delete(:in_works_ids)
        next_actor.create(env) && add_to_works(env, work_ids)
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if update was successful
      def update(env)
        work_ids = env.attributes.delete(:in_works_ids)
        add_to_works(env, work_ids) && next_actor.update(env)
      end

      private

        def can_edit_both_works?(env, work)
          env.current_ability.can?(:edit, work) && env.current_ability.can?(:edit, env.curation_concern)
        end

        def add_to_works(env, new_work_ids)
          return true if new_work_ids.nil?
          cleanup_ids_to_remove_from_curation_concern(env, new_work_ids)
          add_new_work_ids_not_already_in_curation_concern(env, new_work_ids)
          env.curation_concern.errors[:in_works_ids].empty?
        end

        def cleanup_ids_to_remove_from_curation_concern(env, new_work_ids)
          (env.curation_concern.in_works_ids - new_work_ids).each do |old_id|
            work = ::ActiveFedora::Base.find(old_id)
            work.ordered_members.delete(env.curation_concern)
            work.members.delete(env.curation_concern)
            work.save!
          end
        end

        def add_new_work_ids_not_already_in_curation_concern(env, new_work_ids)
          # add to new so long as the depositor for the parent and child matches, otherwise inject an error
          (new_work_ids - env.curation_concern.in_works_ids).each do |work_id|
            work = ::ActiveFedora::Base.find(work_id)
            if can_edit_both_works?(env, work)
              work.ordered_members << env.curation_concern
              work.save!
            else
              env.curation_concern.errors[:in_works_ids] << "Works can only be related to each other if user has ability to edit both."
            end
          end
        end
    end
  end
end
