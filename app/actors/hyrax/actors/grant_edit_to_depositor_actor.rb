module Hyrax
  module Actors
    # Gives the depositor edit access to their work
    class GrantEditToDepositorActor < Hyrax::Actors::AbstractActor
      # @param [Hyrax::Actors::Environment] env
      # @return [Valkyrie::Resource,FalseClass] the saved resource if creates was successful
      def create(env)
        env.change_set.edit_users += [env.user.user_key]
        next_actor.create(env)
      end
    end
  end
end
