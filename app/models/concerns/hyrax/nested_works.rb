module Hyrax
  module NestedWorks
    extend ActiveSupport::Concern

    included do
      class_attribute :valid_child_concerns
      self.valid_child_concerns = Hyrax::ClassifyConcern.new.all_curation_concern_classes
    end

    def in_works_ids
      in_works.map(&:id)
    end
  end
end
