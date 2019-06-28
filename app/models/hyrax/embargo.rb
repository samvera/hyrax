# frozen_string_literal: true

module Hyrax
  ##
  # The Valkyrie model for embargos.
  class Embargo < Valkyrie::Resource
    attribute :visibility_after_embargo,  Valkyrie::Types::String
    attribute :visibility_during_embargo, Valkyrie::Types::String
    attribute :embargo_release_date,      Valkyrie::Types::DateTime
    attribute :embargo_history,           Valkyrie::Types::Array

    def active?
      (embargo_release_date.present? && Time.zone.today < embargo_release_date)
    end
  end
end
