class AuditJob < ActiveFedoraPidBasedJob
  def queue_name
    :audit
  end

  PASS = 'Passing Audit Run'
  FAIL = 'Failing Audit Run'

  attr_accessor :pid, :datastream_id, :version_id

  def initialize(pid, datastream_id, version_id)
    super(pid)
    self.datastream_id = datastream_id
    self.version_id = version_id
  end

  def run
    if generic_file
      datastream = generic_file.datastreams[datastream_id]
      if datastream
        version =  datastream.versions.select { |v| v.versionID == version_id}.first
        log = run_audit(version)

        # look up the user for sending the message to
        login = generic_file.depositor
        if login
          user = User.find_by_user_key(login)
          ActiveFedora::Base.logger.warn "User '#{login}' not found" unless user
          job_user = User.audituser()
          # send the user a message about the failing audit
          unless (log.pass == 1)
            message = "The audit run at #{log.created_at} for #{log.pid}:#{log.dsid}:#{log.version} was #{log.pass == 1 ? 'passing' : 'failing'}."
            subject = (log.pass == 1 ? PASS : FAIL)
            job_user.send_message(user, message, subject)
          end 
        end
      else
        ActiveFedora::Base.logger.warn "No datastream for audit!!!!! pid: #{pid} dsid: #{datastream_id}"
      end
    else
      ActiveFedora::Base.logger.warn "No generic file for data stream audit!!!!! pid: #{pid} dsid: #{datastream_id}"
    end
  end

  private
  def run_audit(version)
    object.class.run_audit(version)
  end
end
