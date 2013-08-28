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
    #logger.info "GF is #{generic_file.pid}"
    if generic_file
      datastream = generic_file.datastreams[datastream_id]
      #logger.info "DS is #{datastream.inspect}"
      if datastream
        #logger.info "Datastream for audit = #{datastream.inspect}"
        version =  datastream.versions.select { |v| v.versionID == version_id}.first
        log = run_audit(version)

        # look up the user for sending the message to
        login = generic_file.depositor
        #logger.info "User login is #{login}"`
        #logger.info "All users = #{User.all}"
        if login
          user = User.find_by_user_key(login)
          logger.warn "User '#{login}' not found" unless user
          #logger.info "ZZZ user = #{user.inspect}"
          job_user = User.audituser()
          #send the user a message about the failing audit
          unless (log.pass == 1)
            message = "The audit run at #{log.created_at} for #{log.pid}:#{log.dsid}:#{log.version} was #{log.pass == 1 ? 'passing' : 'failing'}."
            subject = (log.pass == 1 ? PASS : FAIL)
            job_user.send_message(user, message, subject)
          end 
        end
      else
        logger.warn "No datastream for audit!!!!! pid: #{pid} dsid: #{datastream_id}"
      end
    else
      logger.warn "No generic file for data stream audit!!!!! pid: #{pid} dsid: #{datastream_id}"
    end
  end

  private
  def run_audit(version)
    object.class.run_audit(version)
  end
end
