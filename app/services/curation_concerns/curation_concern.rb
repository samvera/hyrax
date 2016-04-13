module CurationConcerns
  class CurationConcern
    class_attribute :actor_factory
    self.actor_factory = CurationConcerns::ActorFactory

    # A consumer of this method can inject a different factory
    # into this class in order to change the behavior of this method.
    # @param [ActiveFedora::Base] curation_concern a work to be updated
    # @param [User] current_user the depositor/updater of the work
    # @return [#create, #update] an actor that can create and update the work
    def self.actor(curation_concern, current_user)
      actor_factory.build(curation_concern, current_user)
    end
  end
end
