module Hyrax
  module NestedWorks
    extend ActiveSupport::Concern

    included do
      class_attribute :valid_child_concerns
      self.valid_child_concerns = Hyrax.config.work_types
    end

    def in_works_ids
      in_works.map(&:id)
    end
  end
end
