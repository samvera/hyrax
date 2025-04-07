# frozen_string_literal: true

# migrates a resource's sipity entity so it can be found
class MigrateSipityEntityJob < ApplicationJob
  # input [String] id of a migrated resource
  def perform(id:)
    resource = Hyrax.query_service.find_by(id: id)
    work = resource.internal_resource.constantize.find(id)
    new_gid = Hyrax::GlobalID(resource).to_s
    original_gid = Hyrax::GlobalID(work).to_s
    return if new_gid == original_gid
    original_entity = Sipity::Entity.find_by(proxy_for_global_id: original_gid)
    return if original_entity.nil?
    original_entity.update(proxy_for_global_id: new_gid)
  rescue ActiveFedora::ObjectNotFoundError
    # this happens when the resource was never in Fedora so there is nothing to migrate.
    # We don't want to retry the job so we don't raise an error.
  end
end
