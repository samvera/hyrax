module Hyrax
  module NestedWorks
    extend ActiveSupport::Concern

    included do
      # TODO: Remove?
      class_attribute :valid_child_concerns
      self.valid_child_concerns = Hyrax.config.curation_concerns
    end

    # TODO: Move to WorkChangeSet?
    def in_works
      Hyrax::Queries.find_inverse_references_by(resource: self, property: :member_ids)
    end

    # TODO: Move to WorkChangeSet?
    def in_works_ids
      in_works.map(&:id)
    end
  end
end
