# frozen_string_literal: true

module Frigg
  # Persister for Fedora MetadataAdapter.
  class Persister < Valkyrie::Persistence::Fedora::Persister
    # Persists a resource within Fedora
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
      initialize_repository
      internal_resource = resource.dup
      internal_resource.created_at ||= Time.current
      internal_resource.updated_at = Time.current
      validate_lock_token(internal_resource)
      native_lock = native_lock_token(internal_resource)
      generate_lock_token(internal_resource)
      orm = resource_factory.from_resource(resource: internal_resource)
      alternate_resources = find_or_create_alternate_ids(internal_resource)
    # debugger if resource.is_a? Hyrax::AdministrativeSet
      if !orm.new? || !internal_resource.new_record
        cleanup_alternate_resources(internal_resource) if alternate_resources
        orm.update { |req| update_request_headers(req, native_lock) }
      else
        orm.create
      end
      persisted_resource = resource_factory.to_resource(object: orm)

      alternate_resources ? save_reference_to_resource(persisted_resource, alternate_resources) : persisted_resource
      convert_and_migrate_resource(orm, was_wings)

    rescue Ldp::PreconditionFailed
      raise Valkyrie::Persistence::StaleObjectError, "The object #{internal_resource.id} has been updated by another process."
    rescue Ldp::Gone
      raise Valkyrie::Persistence::ObjectNotFoundError, "The object #{resource.id} is previously persisted but not found at save time."
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
