# frozen_string_literal: true

module Hyrax
  ##
  # The Valkyrie model for leases.
  #
  # @note Embargo and Lease can, in principle, be collapsed into a single model
  #   with a `#visibility_during`, `#visibility_after`, `#end_date`, and
  #   `#history`. We haven't made this transition in order to simplify legacy
  #   support for `Hydra::AccessControls`.
  class Lease < Valkyrie::Resource
    attribute :visibility_after_lease,  Valkyrie::Types::String
    attribute :visibility_during_lease, Valkyrie::Types::String
    attribute :lease_expiration_date,   Valkyrie::Types::DateTime
    attribute :lease_history,           Valkyrie::Types::Array

    def active?
      (lease_expiration_date.present? && Hyrax::TimeService.time_in_utc < lease_expiration_date)
    end
  end
end
