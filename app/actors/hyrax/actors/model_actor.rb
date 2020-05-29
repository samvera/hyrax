module Hyrax
  module Actors
    # This is a proxy for the model specific actor
    class ModelActor < AbstractActor
      # See: https://github.com/bbatsov/rubocop/issues/5393
      # rubocop:disable Rails/Delegate

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
      # rubocop:enable Rails/Delegate

      private

        def model_actor(env)
          actor_identifier = env.curation_concern.class
          klass = "Hyrax::Actors::#{actor_identifier}Actor".constantize
          klass.new(next_actor)
        rescue NameError => error
          Hyrax.logger.info 'No ModelActor provided for ' \
                            "#{env.curation_concern.class}; falling back on " \
                            "NullActor\n\t#{error}"

          NullActor.new(next_actor)
        end
    end
  end
end
