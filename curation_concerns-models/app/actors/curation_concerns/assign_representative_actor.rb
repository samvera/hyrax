module CurationConcerns
  class AssignRepresentativeActor < AbstractActor
    def create(attributes)
      next_actor.create(attributes) && assign_representative
    end

    private

      def assign_representative
        unless curation_concern.representative_id
          # TODO: Possible optimization here. Does this cause a fetch of ordered_members if they're already loaded?
          representative = nil # curation_concern.ordered_members.association.reader.first.target
          curation_concern.representative = representative if representative
        end
        curation_concern.save
      end
  end
end
