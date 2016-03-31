module CurationConcerns
  class AssignIdentifierActor < AbstractActor
    def create
      curation_concern.assign_id && next_actor.create
    end
  end
end
