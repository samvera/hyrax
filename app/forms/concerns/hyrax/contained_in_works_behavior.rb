# frozen_string_literal: true
module Hyrax
  ##
  # A module of form behaviours for resources which can be contained in works.
  module ContainedInWorksBehavior
    ##
    # @api private
    InWorksPrepopulator = proc do |_options|
      self.in_works_ids =
        if persisted?
          Hyrax.query_service
               .find_inverse_references_by(resource: model, property: :member_ids)
               .select(&:work?)
               .map(&:id)
        else
          []
        end
    end

    def self.included(descendant)
      descendant.property :in_works_ids, virtual: true, prepopulator: InWorksPrepopulator
    end
  end
end
