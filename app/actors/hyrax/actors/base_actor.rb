module Hyrax
  module Actors
    ##
    # Defines the basic save/destroy and callback behavior, intended to run
    # near the bottom of the actor stack.
    #
    # @example Defining a base actor for a custom work type
    #   module Hyrax
    #     module Actors
    #       class MyWorkActor < Hyrax::Actors::BaseActor; end
    #     end
    #   end
    #
    # @see Hyrax::Actor::AbstractActor
    class BaseActor < AbstractActor
      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if create was successful
      def create(env)
        assign_modified_date(env)
        yield env.change_set if block_given?
        return unless env.change_set.validate(env.attributes)
        saved_record = save(env)
        saved_record && next_actor.create(env) &&
          run_callbacks(:after_create_concern, saved_record, env.user)
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if update was successful
      def update(env)
        assign_modified_date(env)
        return unless env.change_set.validate(env.attributes)
        next_actor.update(env) && save(env) &&
          run_callbacks(:after_update_metadata, env.resource, env.user)
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if destroy was successful
      def destroy(env)
        env.resource.member_of_collection_ids.each do |id|
          destination_collection = Hyrax::Queries.find_by(id: id)
          destination_collection.members.delete(env.curation_concern)
          solr_persister.save(resource: destination_collection)
        end

        env.change_set_persister.buffer_into_index do |persist|
          persist.delete(change_set: env.change_set)
        end
      end

      private

        def solr_persister
          @solr_persister ||= Valkyrie::MetadataAdapter.find(:index_solr).persister
        end

        def run_callbacks(hook, resource, user)
          Hyrax.config.callback.run(hook, resource, user)
          true
        end

        # @return [Valkyrie::Resource] the saved resource if it is successful
        def save(env)
          env.change_set.sync
          resource = nil
          env.change_set_persister.buffer_into_index do |persist|
            resource = persist.save(change_set: env.change_set)
          end
          resource
        end

        def assign_modified_date(env)
          env.curation_concern.date_modified = TimeService.time_in_utc
        end
    end
  end
end
