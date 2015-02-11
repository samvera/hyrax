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
      file.visibility = work.visibility  # visibility must come first, because it can clear an embargo/lease
      file.lease.attributes = work.lease.attributes.except("id")
      file.lease.save
      file.embargo.attributes = work.embargo.attributes.except("id")
      file.embargo.save
      file.save!
    end
  end
end

