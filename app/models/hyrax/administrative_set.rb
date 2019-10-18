# frozen_string_literal: true

module Hyrax
  ##
  # Valkyrie model for Admin Set domain objects.
  class AdministrativeSet < Hyrax::Resource
    attribute :alt_title,   Valkyrie::Types::Set.of(Valkyrie::Types::String)
    attribute :creator,     Valkyrie::Types::Set.of(Valkyrie::Types::String)
    attribute :description, Valkyrie::Types::Set.of(Valkyrie::Types::String)
    attribute :title,       Valkyrie::Types::Set.of(Valkyrie::Types::String)
  end
end
