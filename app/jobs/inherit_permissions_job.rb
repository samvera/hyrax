# frozen_string_literal: true
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

  # Returns a list of member file_sets for a work
  # @param work [Resource]
  # @return [Array<Hyrax::File_Set>]
  def file_sets_for(work)
    Hyrax.custom_queries.find_child_filesets(resource: work)
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
    work_permissions = Hyrax::AccessControlList.new(resource: work).permissions

    file_sets_for(work).each do |file_set|
      acl = Hyrax::AccessControlList.new(resource: file_set)
      acl.permissions = work_permissions
      acl.save
    end
  end
end
