# frozen_string_literal: true

module Hyrax
  ##
  # Valkyrie model for Admin Set domain objects.
  class AdministrativeSet < Hyrax::Resource
    include Hyrax::Schema(:core_metadata)

    attribute :alternative_title, Valkyrie::Types::Set.of(Valkyrie::Types::String)
    attribute :creator,           Valkyrie::Types::Set.of(Valkyrie::Types::String)
    attribute :description,       Valkyrie::Types::Set.of(Valkyrie::Types::String)

    def collection_type_gid
      # allow AdministrativeSet to behave more like a regular PcdmCollection
      Hyrax::CollectionType.find_or_create_admin_set_type.to_global_id
    end
  end
end
