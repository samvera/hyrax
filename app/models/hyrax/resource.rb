# frozen_string_literal: true

module Hyrax
  ##
  # The base Valkyrie model for Hyrax.
  class Resource < Valkyrie::Resource
    include Valkyrie::Resource::AccessControls

    attribute :alternate_ids, ::Valkyrie::Types::Array
    attribute :visibility,    ::Valkyrie::Types::String
    attribute :embargo_id,    Valkyrie::Types::ID
  end
end
