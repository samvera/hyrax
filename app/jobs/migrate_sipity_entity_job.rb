# frozen_string_literal: true

# migrates a resource's sipity entity so it can be found
class MigrateSipityEntityJob < ApplicationJob
  # input [String] id of a migrated resource
  def perform(id:)
    resource = Hyrax.query_service.find_by(id: id)
    new_gid = Hyrax::GlobalID(resource).to_s
    work = resource.internal_resource.constantize.find(id)
    original_gid = Hyrax::GlobalID(work).to_s
    return if new_gid == original_gid
    original_entity = Sipity::Entity.find_by(proxy_for_global_id: original_gid)
    original_entity.update(proxy_for_global_id: new_gid)
  end
end
