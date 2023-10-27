# frozen_string_literal: true

module Frigg
  # Persister for Postgres MetadataAdapter.
  class Persister < Valkyrie::Persistence::Fedora::Persister
    # Persists a resource within the database
    #
    # Modified from the upstream to skip previously persisted check
    #
    # @param [Valkyrie::Resource] resource
    # @return [Valkyrie::Resource] the persisted/updated resource
    # @raise [Valkyrie::Persistence::StaleObjectError] raised if the resource
    #   was modified in the database between been read into memory and persisted
    # rubocop:disable Lint/UnusedMethodArgument
    def save(resource:, external_resource: false, perform_af_validation: false)
      # TODO
      #   orm_object = resource_factory.from_resource(resource: resource)
      #   orm_object.transaction do
      #     orm_object.save!
      #     if resource.id && resource.id.to_s != orm_object.id
      #       raise Valkyrie::Persistence::UnsupportedDatatype,
      #             "Postgres' primary key column can not save with the given ID #{resource.id}. " \
      #             "To avoid this error, set the ID to be nil via `resource.id = nil` before you save it. \n" \
      #             "Called from #{Gem.location_of_caller.join(':')}"
      #     end
      #   end
      #   resource_factory.to_resource(object: orm_object)
      # rescue ActiveRecord::StaleObjectError
      #   raise Valkyrie::Persistence::StaleObjectError, "The object #{resource.id} has been updated by another process."
    end
    # rubocop:enable Lint/UnusedMethodArgument
  end
end
