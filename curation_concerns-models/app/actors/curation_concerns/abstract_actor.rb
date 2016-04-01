module CurationConcerns
  # The CurationConcern Abstract actor responds to two primary actions:
  # * #create
  # * #update
  #
  # and the following attributes
  #
  # * next_actor
  # * curation_concern
  # * user
  #
  # it must instantiate the next actor in the chain and instantiate it.
  # it should respond to curation_concern, user and attributes.
  # it ha to next_actor
  class AbstractActor
    attr_reader :next_actor

    def initialize(_curation_concern, _user, next_actor)
      @next_actor = next_actor
    end

    delegate :curation_concern, :user, to: :next_actor

    delegate :create, to: :next_actor

    delegate :update, to: :next_actor
  end
end
