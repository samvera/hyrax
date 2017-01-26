# A job to apply work permissions to all contained files set
#
class InheritPermissionsJob < ActiveJob::Base
  before_enqueue do |job|
    log = job.arguments.last
    log.pending_job(self)
  end

  # Perform the copy from the work to the contained filesets
  #
  # @param [Hydra::Works::Work] work - work containing access level and filesets
  # @param [Hyrax::Operation] log - a log storing the status of the job
  def perform(work, log)
    log.performing!
    work.file_sets.each do |file|
      child_log = Hyrax::Operation.create!(user: depositor(work),
                                           operation_type: 'Inherit Permissions',
                                           parent: log)
      child_log.performing!
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
      if file.valid?
        child_log.success!
      else
        child_log.fail!(file.errors.full_messages.join(' '))
      end
      file.save!
    end
    # Explicitly log success if operation has no children; else, children handle setting the status of the parent
    log.success! if log.children.none?
  end

  private

    def depositor(work)
      ::User.find_by_user_key(work.depositor)
    end
end
