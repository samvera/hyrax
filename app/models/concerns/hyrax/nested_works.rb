# frozen_string_literal: true
module Hyrax
  module NestedWorks
    extend ActiveSupport::Concern

    included do
      class_attribute :valid_child_concerns
      self.valid_child_concerns = Hyrax.config.curation_concerns
    end

    def in_works_ids
      in_works.map(&:id)
    end
  end
end
