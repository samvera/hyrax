module Hyrax
  module Actors
    # Adds the work in the environment as a child of the works in the `in_work_ids`
    # parameter
    # TODO: Valkyrie moves this functionality into the ChangeSetPersister. We could
    # consider doing the same
    class AddToWorkActor < AbstractActor
      # @param [Hyrax::Actors::Environment] env
      # @return [Valkyrie::Resource,FalseClass] the saved resource if create was successful
      def create(env)
        work_ids = env.attributes.delete(:in_works_ids)
        saved_resource = next_actor.create(env)
        return saved_resource if saved_resource && add_to_works(env, saved_resource, work_ids)
        false
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Valkyrie::Resource,FalseClass] the saved resource if update was successful
      def update(env)
        work_ids = env.attributes.delete(:in_works_ids)
        add_to_works(env, env.curation_concern, work_ids) && next_actor.update(env)
      end

      private

        # TODO: the controller has already checked that they have edit permission
        # on the child_work. We really only need to check `work`
        def can_edit_both_works?(ability, child_work, work)
          ability.can?(:edit, work) && ability.can?(:edit, child_work)
        end

        def add_to_works(env, child_work, new_work_ids)
          return true if new_work_ids.nil?
          cleanup_ids_to_remove_from_curation_concern(child_work, new_work_ids)
          add_new_work_ids_not_already_in_curation_concern(env, child_work, new_work_ids)
          env.change_set.errors[:in_works_ids].empty?
        end

        def cleanup_ids_to_remove_from_curation_concern(child_work, new_work_ids)
          (child_work.in_works_ids - new_work_ids).each do |old_id|
            work = find_resource(old_id)
            work.member_ids.delete(child_work.id)
            persister.save(resource: work)
          end
        end

        def add_new_work_ids_not_already_in_curation_concern(env, child_work, new_work_ids)
          # add to new so long as the depositor for the parent and child matches, otherwise inject an error
          (new_work_ids - child_work.in_works_ids).each do |work_id|
            work = find_resource(work_id)
            if can_edit_both_works?(env.current_ability, child_work, work)
              work.member_ids += [child_work.id]
              persister.save(resource: work)
            else
              env.change_set.errors[:in_works_ids] << "Works can only be related to each other if user has ability to edit both."
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
