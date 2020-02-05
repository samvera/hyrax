# frozen_string_literal: true

module Hyrax
  ##
  # Valkyrie model for `Work` domain objects in the Hydra Works model.
  #
  # @see https://wiki.duraspace.org/display/samvera/Hydra%3A%3AWorks+Shared+Modeling
  class Work < Hyrax::Resource
    include Hyrax::Schema(:core_metadata)

    attribute :admin_set_id,             Valkyrie::Types::ID
    attribute :member_ids,               Valkyrie::Types::Array.of(Valkyrie::Types::ID).meta(ordered: true)
    attribute :member_of_collection_ids, Valkyrie::Types::Set.of(Valkyrie::Types::ID)
    attribute :state,                    Valkyrie::Types::URI.default(Hyrax::ResourceStatus::ACTIVE)

    ##
    # @return [Boolean] true
    def pcdm_object?
      true
    end

    ##
    # @return [Boolean] true
    def work?
      true
    end
  end
end
