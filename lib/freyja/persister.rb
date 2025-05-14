# frozen_string_literal: true

module Freyja
  # Persister for Postgres MetadataAdapter.
  class Persister < Valkyrie::Persistence::Postgres::Persister
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
      was_wings = resource.respond_to?(:wings?) && resource.wings?
      orm_object = resource_factory.from_resource(resource: resource)
      orm_object.transaction do
        orm_object.save!
        if resource.id && resource.id.to_s != orm_object.id
          raise Valkyrie::Persistence::UnsupportedDatatype,
                "Postgres' primary key column can not save with the given ID #{resource.id}. " \
                "To avoid this error, set the ID to be nil via `resource.id = nil` before you save it. \n" \
                "Called from #{Gem.location_of_caller.join(':')}"
        end
      end
      convert_and_migrate_resource(orm_object, was_wings)

    rescue ActiveRecord::StaleObjectError
      raise Valkyrie::Persistence::StaleObjectError, "The object #{resource.id} has been updated by another process."
    end
    # rubocop:enable Lint/UnusedMethodArgument

    def convert_and_migrate_resource(orm_object, was_wings)
      new_resource = resource_factory.to_resource(object: orm_object)
      # if the resource was wings and is now a Valkyrie resource, we need to migrate sipity, files, and members
      if Hyrax.config.valkyrie_transition? && was_wings && !new_resource.wings?
        MigrateFilesToValkyrieJob.perform_later(new_resource) if new_resource.is_a?(Hyrax::FileSet) && new_resource.file_ids.size == 1 && new_resource.file_ids.first.id.to_s.match('/files/')
        # migrate any members if the resource is a Hyrax work
        if new_resource.is_a?(Hyrax::Work)
          member_ids = new_resource.member_ids.map(&:to_s)
          MigrateResourcesJob.perform_later(ids: member_ids) unless member_ids.empty?
          MigrateSipityEntityJob.perform_now(id: new_resource.id.to_s)
        end
      end
      new_resource
    end
  end
end
