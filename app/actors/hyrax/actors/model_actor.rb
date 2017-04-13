module Hyrax
  module Actors
    # This is a proxy for the model specific actor
    class ModelActor < AbstractActor
      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if update was successful
      def update(env)
        model_actor(env).update(env)
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if create was successful
      def create(env)
        model_actor(env).create(env)
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if destroy was successful
      def destroy(env)
        model_actor(env).destroy(env)
      end

      private

        def model_actor(env)
          actor_identifier = env.curation_concern.class.to_s.split('::').last
          klass = "Hyrax::Actors::#{actor_identifier}Actor".constantize
          klass.new(next_actor)
        end
    end
  end
end
