module Hyrax
  class CurationConcern
    # This attribute is set by Hyrax::Engine
    class_attribute :actor_factory

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
