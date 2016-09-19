# A job to apply work permissions to all contained files set
#
class InheritPermissionsJob < ActiveJob::Base
  # Perform the copy from the work to the contained filesets
  #
  # @param work containing access level and filesets
  def perform(work)
    work.file_sets.each do |file|
      attribute_map = work.permissions.map(&:to_hash)

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
end
