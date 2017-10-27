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
        save(env) && next_actor.create(env) && run_callbacks(:after_create_concern, env)
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if update was successful
      def update(env)
        assign_modified_date(env)
        return unless env.change_set.validate(env.attributes)
        next_actor.update(env) && save(env) && run_callbacks(:after_update_metadata, env)
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if destroy was successful
      def destroy(env)
        env.curation_concern.in_collection_ids.each do |id|
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

        def run_callbacks(hook, env)
          Hyrax.config.callback.run(hook, env.curation_concern, env.user)
          true
        end

        def save(env)
          env.change_set.sync
          env.change_set_persister.buffer_into_index do |persist|
            persist.save(change_set: env.change_set)
          end
        end

        def assign_modified_date(env)
          env.curation_concern.date_modified = TimeService.time_in_utc
        end
    end
  end
end
