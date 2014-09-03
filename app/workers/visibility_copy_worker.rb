class VisibilityCopyWorker
  def queue_name
    :permissions
  end

  attr_accessor :pid

  def initialize(pid)
    self.pid = pid
  end

  def run
    work = ActiveFedora::Base.find(pid)
    work.generic_files.each do |file|
      # visibility must come first, because it can clear an embargo/lease
      file.visibility = work.visibility

      file.embargo_release_date = work.embargo_release_date
      file.visibility_during_embargo = work.visibility_during_embargo
      file.visibility_after_embargo = work.visibility_after_embargo

      file.lease_expiration_date = work.lease_expiration_date
      file.visibility_during_lease = work.visibility_during_lease
      file.visibility_after_lease = work.visibility_after_lease
      file.save!
    end
  end
end

