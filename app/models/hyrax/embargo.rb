# frozen_string_literal: true

module Hyrax
  ##
  # The Valkyrie model for embargoes.
  #
  # @note Embargo and Lease can, in principle, be collapsed into a single model
  #   with a `#visibility_during`, `#visibility_after`, `#end_date`, and
  #   `#history`. We haven't made this transition in order to simplify legacy
  #   support for `Hydra::AccessControls`.
  class Embargo < Valkyrie::Resource
    attribute :visibility_after_embargo,  Valkyrie::Types::String
    attribute :visibility_during_embargo, Valkyrie::Types::String
    attribute :embargo_release_date,      Valkyrie::Types::DateTime
    attribute :embargo_history,           Valkyrie::Types::Array

    def active?
      (embargo_release_date.present? && Hyrax::TimeService.time_in_utc < embargo_release_date)
    end
  end
end
