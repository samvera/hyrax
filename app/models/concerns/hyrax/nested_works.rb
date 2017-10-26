module Hyrax
  module NestedWorks
    extend ActiveSupport::Concern

    included do
      class_attribute :valid_child_concerns
      self.valid_child_concerns = Hyrax.config.curation_concerns
    end

    def in_works_ids
      Hyrax::Queries.find_inverse_references_by(resource: self, property: :member_ids)
    end
  end
end
