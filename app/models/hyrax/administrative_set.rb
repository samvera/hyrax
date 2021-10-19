# frozen_string_literal: true

module Hyrax
  ##
  # Valkyrie model for Admin Set domain objects.
  class AdministrativeSet < Hyrax::Resource
    include Hyrax::Schema(:core_metadata)

    attribute :alternative_title, Valkyrie::Types::Set.of(Valkyrie::Types::String)
    attribute :creator,           Valkyrie::Types::Set.of(Valkyrie::Types::String)
    attribute :description,       Valkyrie::Types::Set.of(Valkyrie::Types::String)

    ##
    # @note all admin sets have the same collection type, so we don't store
    #   this data. however, we want a reader so type lookup behaves the same
    #   as for other collections.
    # @return [GlobalID]
    def collection_type_gid
      self.class.collection_type_gid
    end

    def self.collection_type_gid
      GlobalID.new(URI::GID.build([GlobalID.app,
                                   Hyrax::CollectionType.name,
                                   Hyrax.admin_set_collection_type_id,
                                   {}]))
    end
  end
end
