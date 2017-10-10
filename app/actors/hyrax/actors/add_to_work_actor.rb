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
            work = find_resource(old_id)
            work.member_ids.delete(env.curation_concern.id)
            persister.save(resource: work)
          end
        end

        def add_new_work_ids_not_already_in_curation_concern(env, new_work_ids)
          # add to new so long as the depositor for the parent and child matches, otherwise inject an error
          (new_work_ids - env.curation_concern.in_works_ids).each do |work_id|
            work = find_resource(work_id)
            if can_edit_both_works?(env, work)
              work.member_ids << env.curation_concern.id
              persister.save(resource: work)
            else
              env.curation_concern.errors[:in_works_ids] << "Works can only be related to each other if user has ability to edit both."
            end
          end
        end

        def find_resource(id)
          query_service.find_by(id: Valkyrie::ID.new(id.to_s))
        end

        delegate :query_service, :persister, to: :indexing_adapter

        def indexing_adapter
          @indexing_adapter ||= Valkyrie::MetadataAdapter.find(:indexing_persister)
        end
    end
  end
end
