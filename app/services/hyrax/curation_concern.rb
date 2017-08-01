module Hyrax
  class CurationConcern
    # The actor middleware stack can be customized like so:
    #   # Adding a new middleware
    #   Hyrax::CurationConcern.actor_factory.use MyCustomActor
    #
    #   # Inserting a new middleware at a specific position
    #   Hyrax::CurationConcern.actor_factory.insert_after Hyrax::Actors::CreateWithRemoteFilesActor, MyCustomActor
    #
    #   # Removing a middleware
    #   Hyrax::CurationConcern.actor_factory.delete Hyrax::Actors::CreateWithRemoteFilesActor
    #
    #   # Replace one middleware with another
    #   Hyrax::CurationConcern.actor_factory.swap Hyrax::Actors::CreateWithRemoteFilesActor, MyCustomActor
    #
    # You can customize the actor stack, so long as you do so before the actor
    # is used.  Once it is used, it becomes immutable.
    # @return [Hyrax::ActorFactory]
    def self.actor_factory
      Hyrax::ActorFactory
    end

    # A consumer of this method can inject a different factory
    # into this class in order to change the behavior of this method.
    # @param [ActiveFedora::Base] curation_concern a work to be updated
    # @param [Ability] current_ability the permission object for depositing this
    #   work.
    # @return [#create, #update] an actor that can create and update the work
    def self.actor(curation_concern, current_ability)
      actor_factory.build(curation_concern, current_ability)
    end
  end
end
