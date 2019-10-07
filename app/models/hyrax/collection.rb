# frozen_string_literal: true

module Hyrax
  ##
  # Valkyrie model for `Collection` domain objects in the Hydra Works model.
  class Collection < Hyrax::Resource
    include Hyrax::Schema(:core_metadata)

    attribute :collection_type_gid, Valkyrie::Types::String
    attribute :member_of_collection_ids, Valkyrie::Types::Set.of(Valkyrie::Types::ID)
    attribute :member_ids, Valkyrie::Types::Array.of(Valkyrie::Types::ID).meta(ordered: true)
  end
end
