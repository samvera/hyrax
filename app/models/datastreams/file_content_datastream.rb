require 'open3'
class FileContentDatastream < ActiveFedora::Datastream
  include Open3

  # Verify that the checksum for this datastream is valid and record a ChecksumAuditLog
  def audit
    passing = self.dsChecksumValid
    prune_history if passing
    ChecksumAuditLog.create!(:pass=>passing, :dsid=>dsid, :pid=>pid, :version=>dsVersionID)
  end
  

  def extract_metadata
    f = Tempfile.new("#{pid}-#{dsVersionID}")
    f.binmode
    f.puts content
    f.close
    command = "#{fits_path} -i #{f.path}"
    stdin, stdout, stderr = popen3(command)
    stdin.close
    out = stdout.read
    stdout.close
    err = stderr.read
    stderr.close
    raise "Unable to execute command \"#{command}\"\n#{err}" unless err.empty?
    f.unlink
    out
  end


  def fits_path
    Rails.application.config.fits_path
  end

  def logs
    ChecksumAuditLog.where(:dsid=>dsid, :pid=>pid).order('created_at desc')
  end

  private
  def prune_history
    ## Check to see if there are previous passing logs that we can delete
    # we want to keep the first passing event after a failure, the most current passing event, and all failures so that this table doesn't grow too large
    # Simple way (a little naieve): if the last 2 were passing, delete the first one
    list = logs.limit(2)
    if list.size > 1 && list[0].pass && list[1].pass
      list[0].delete 
    end
  end
  

end
