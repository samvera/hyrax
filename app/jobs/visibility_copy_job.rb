# Responsible for copying the following attributes from the work to each file in the file_sets
#
# * visibility
# * lease
# * embargo
class VisibilityCopyJob < Hyrax::ApplicationJob
  # @api public
  # @param work_id [String] the identifier for a work
  def perform(work_id)
    work = Hyrax::Queries.find_by(id: Valkyrie::ID.new(work_id))
    work.file_sets.each do |file|
      file.visibility = work.visibility # visibility must come first, because it can clear an embargo/lease

      copy_lease(work: work, file: file)
      copy_embargo(work: work, file: file)

      persister.save(resource: file)
    end
  end

  private

    def copy_lease(work:, file:)
      return unless work.lease_id
      work_lease = Hyrax::Queries.find_by(id: work.lease_id)
      file_lease = if file.lease_id
                     Hyrax::Queries.find_by(id: file.lease_id)
                   else
                     Hyrax::Lease.new
                   end
      file_lease.lease_expiration_date = work_lease.lease_expiration_date
      file_lease.visibility_during_lease = work_lease.visibility_during_lease
      file_lease.visibility_after_lease = work_lease.visibility_after_lease
      saved = persister.save(resource: file_lease)
      file.lease_id = saved.id
    end

    def copy_embargo(work:, file:)
      return unless work.embargo_id
      work_embargo = Hyrax::Queries.find_by(id: work.embargo_id)
      file_embargo = if file.embargo_id
                       Hyrax::Queries.find_by(id: file.embargo_id)
                     else
                       Hyrax::Embargo.new
                     end
      file_embargo.embargo_release_date = work_embargo.embargo_release_date
      file_embargo.visibility_during_embargo = work_embargo.visibility_during_embargo
      file_embargo.visibility_after_embargo = work_embargo.visibility_after_embargo
      saved = persister.save(resource: file_embargo)
      file.embargo_id = saved.id
    end

    def persister
      Valkyrie::MetadataAdapter.find(:indexing_persister).persister
    end
end
