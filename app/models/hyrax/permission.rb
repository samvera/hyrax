# frozen_string_literal: true

module Hyrax
  ##
  # Valkyrie native permissions (access policies) for Hyrax
  #
  # Permissions are persisted independently from `Hyrax::Resource`s (works,
  # collections, file sets, etc...) since their scope is different. Access policies
  # may be application-specific and tend to update more frequently than resource
  # metadata. This approach also allows policies to be persisted using a
  # different database or adapter than is used for curatorial objects.
  class Permission < Valkyrie::Resource
    include Dry::Equalizer(:access_to, :agent, :mode)

    attribute :access_to, Valkyrie::Types::ID
    attribute :agent,     Valkyrie::Types::String
    attribute :mode,      Valkyrie::Types::Coercible::Symbol
  end
end
