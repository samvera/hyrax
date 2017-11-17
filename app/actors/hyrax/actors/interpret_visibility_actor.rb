module Hyrax
  module Actors
    class InterpretVisibilityActor < AbstractActor
      class Intention
        def initialize(attributes)
          @attributes = attributes
        end

        # returns a copy of attributes with the necessary params removed
        # If the lease or embargo is valid, or if they selected something besides lease
        # or embargo, remove all the params.
        def sanitize_params
          if valid_lease?
            sanitize_lease_params
          elsif valid_embargo?
            sanitize_embargo_params
          elsif !wants_lease? && !wants_embargo?
            sanitize_unrestricted_params
          else
            @attributes
          end
        end

        def wants_lease?
          visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LEASE
        end

        def wants_embargo?
          visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO
        end

        def valid_lease?
          wants_lease? && @attributes[:lease_expiration_date].present?
        end

        def valid_embargo?
          wants_embargo? && @attributes[:embargo_release_date].present?
        end

        def lease_params
          [:lease_expiration_date,
           :visibility_during_lease,
           :visibility_after_lease].map { |key| @attributes[key] }
        end

        def embargo_params
          [:embargo_release_date,
           :visibility_during_embargo,
           :visibility_after_embargo].map { |key| @attributes[key] }
        end

        private

          def sanitize_unrestricted_params
            @attributes.except(:lease_expiration_date,
                               :visibility_during_lease,
                               :visibility_after_lease,
                               :embargo_release_date,
                               :visibility_during_embargo,
                               :visibility_after_embargo)
          end

          def sanitize_lease_params
            @attributes.except(:visibility,
                               :lease_expiration_date,
                               :visibility_during_lease,
                               :visibility_after_lease)
          end

          def sanitize_embargo_params
            @attributes.except(:visibility,
                               :embargo_release_date,
                               :visibility_during_embargo,
                               :visibility_after_embargo)
          end

          def visibility
            @attributes[:visibility]
          end
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Valkyrie::Resource,FalseClass] the saved resource if create was successful
      def create(env)
        intention = Intention.new(env.attributes)
        attributes = intention.sanitize_params
        new_env = duplicate_env(env, attributes)
        apply_visibility(new_env, intention) &&
          next_actor.create(new_env)
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Valkyrie::Resource,FalseClass] the saved resource if update was successful
      def update(env)
        intention = Intention.new(env.attributes)
        attributes = intention.sanitize_params
        new_env = duplicate_env(env, attributes)
        apply_visibility(new_env, intention) &&
          next_actor.update(new_env)
      end

      private

        def duplicate_env(env, attributes)
          Environment.new(env.change_set, env.change_set_persister, env.current_ability, attributes)
        end

        def apply_visibility(env, intention)
          apply_lease(env, intention) && apply_embargo(env, intention).tap do
            if env.attributes[:visibility]
              env.curation_concern.visibility = env.attributes[:visibility]
            end
          end
        end

        # If they want a lease, we can assume it's valid
        def apply_lease(env, intention)
          return true unless intention.wants_lease?
          lease = find_or_initialize_lease(env.curation_concern)

          lease.lease_expiration_date = [DateTime.parse(intention.lease_params[0]).in_time_zone]
          lease.visibility_during_lease = intention.lease_params[1]
          lease.visibility_after_lease = intention.lease_params[2]
          saved = env.change_set_persister.persister.save(resource: lease)

          env.curation_concern.lease_id = saved.id
          env.curation_concern.assign_lease_visibility(lease)
        end

        # If they want an embargo, we can assume it's valid
        def apply_embargo(env, intention)
          return true unless intention.wants_embargo?
          embargo = find_or_initialize_embargo(env.curation_concern)

          embargo.embargo_release_date = [DateTime.parse(intention.embargo_params[0]).in_time_zone]
          embargo.visibility_during_embargo = intention.embargo_params[1]
          embargo.visibility_after_embargo = intention.embargo_params[2]
          saved = env.change_set_persister.persister.save(resource: embargo)

          env.curation_concern.embargo_id = saved.id
          env.curation_concern.assign_embargo_visibility(embargo)
        end

        def find_or_initialize_embargo(work)
          if work.embargo_id
            Hyrax::Queries.find_by(id: work.embargo_id)
          else
            Hyrax::Embargo.new
          end
        end

        def find_or_initialize_lease(work)
          if work.lease_id
            Hyrax::Queries.find_by(id: work.lease_id)
          else
            Hyrax::Lease.new
          end
        end
    end
  end
end
