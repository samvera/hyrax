# frozen_string_literal: true

module Hyrax
  ##
  # Valkyrie model for `Work` domain objects in the Hydra Works model.
  #
  # @see https://wiki.duraspace.org/display/samvera/Hydra%3A%3AWorks+Shared+Modeling
  class Work < Hyrax::Resource
    include Hyrax::Schema(:core_metadata)

    attribute :admin_set_id, Valkyrie::Types::ID
    attribute :member_ids,   Valkyrie::Types::Array.of(Valkyrie::Types::ID).meta(ordered: true)

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

    ##
    # @return [#to_solr]
    def indexer
      Hyrax::ValkyrieWorkIndexer.new(resource: self)
    end
  end
end
