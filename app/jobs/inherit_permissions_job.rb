# A job to apply work permissions to all contained files set
#
class InheritPermissionsJob < Hyrax::ApplicationJob
  # Perform the copy from the work to the contained filesets
  #
  # @param work containing access level and filesets
  # @param use_valkyrie [Boolean] whether to use valkyrie support
  def perform(work, use_valkyrie: Hyrax.config.use_valkyrie?)
    if use_valkyrie
      valkyrie_perform(work)
    else
      af_perform(work)
    end
  end

  private

  # Return array of hashes representing permissions without their :access_to objects
  # @param permissions [Permission]
  # @return [Array<Hash>]
  def permissions_map(permissions)
    permissions.collect { |p| { agent: agent_object(p.agent), mode: p.mode } }
  end

  # Returns a list of member file_sets for a work
  # @param work [Resource]
  # @return [Array<Hyrax::File_Set>]
  def file_sets_for(work)
    Hyrax.query_service.custom_queries.find_child_filesets(resource: work)
  end

  # Converts string representation of Permission.agent to either User or Hyrax::Group
  # @param agent [String]
  # @return [User] or [Hyrax::Group]
  def agent_object(agent)
    return Hyrax::Group.new(agent.sub(Hyrax::Group.name_prefix, '')) if agent.starts_with?(Hyrax::Group.name_prefix)
    User.find_by_user_key(agent)
  end

  # Perform the copy from the work to the contained filesets
  #
  # @param work containing access level and filesets
  def af_perform(work)
    attribute_map = work.permissions.map(&:to_hash)
    work.file_sets.each do |file|
      # copy and removed access to the new access with the delete flag
      file.permissions.map(&:to_hash).each do |perm|
        unless attribute_map.include?(perm)
          perm[:_destroy] = true
          attribute_map << perm
        end
      end
      # apply the new and deleted attributes
      file.permissions_attributes = attribute_map
      file.save!
    end
  end

  # Perform the copy from the work to the contained filesets
  #
  # @param work containing access level and filesets
  def valkyrie_perform(work)
    work_permissions = permissions_map(work.permission_manager.acl.permissions)
    file_sets_for(work).each do |file|
      file_acl = Hyrax::AccessControlList.new(resource: file)
      file_permissions = permissions_map(file_acl.permissions)
      # grant new work permissions to member file_sets
      (work_permissions - file_permissions).each { |perm| file_acl.grant(perm[:mode]).to(perm[:agent]).save }
      # remove permissions that are not on work from member file_sets
      (file_permissions - work_permissions).each { |perm| file_acl.revoke(perm[:mode]).from(perm[:agent]).save }
      file_acl.save
    end
  end
end
