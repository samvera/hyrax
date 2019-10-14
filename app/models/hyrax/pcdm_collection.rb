# frozen_string_literal: true

module Hyrax
  ##
  # Valkyrie model for Collection domain objects in the Hydra Works model.
  class PcdmCollection < Hyrax::Resource
    include Hyrax::Schema(:core_metadata)

    attribute :collection_type_gid, Valkyrie::Types::String
    attribute :member_ids, Valkyrie::Types::Array.of(Valkyrie::Types::ID).meta(ordered: true)
  end
end
