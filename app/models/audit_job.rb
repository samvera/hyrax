class AuditJob
  @queue = :audit

  PASS = 'Passing Audit Run'
  FAIL = 'Failing Audit Run'


  def self.perform(generic_file_id, datastream_id, version_id)
    generic_file = GenericFile.find(generic_file_id, :cast => true)
    if generic_file
      datastream = generic_file.datastreams[datastream_id]
      if datastream
        #logger.info "Datastream for audit = #{datastream.inspect}"
        version =  datastream.versions.select { |v| v.versionID == version_id}.first
        log = GenericFile.run_audit(version)

        # look up the user for sending the message to
        login = generic_file.depositor
        if login
          user = User.find_by_login(login)
          #logger.info "User = #{user.inspect}"
          job_user = User.where(login:"audituser").first
          job_user = User.create(login:"audituser", email:"auditemail") unless job_user

          #send the user a message about the audit
          # TODO: do we want to do this on failing only?
          message = "The audit run at #{log.created_at} for #{log.pid}:#{log.dsid}:#{log.version} was #{log.pass == 1 ? 'passing' : 'failing'}."
          subject = log.pass == 1 ? PASS : FAIL
          #logger.info "Sending message #{message} to user #{user.inspect}"
          job_user.send_message(user, message, subject)
        end
      else
        logger.warn "No datastream for audit!!!!! pid: #{generic_file_id} dsid: #{datastream_id}"
      end
    else
      logger.warn "No generic file for data stream audit!!!!! pid: #{generic_file_id} dsid: #{datastream_id}"
    end
  end
end
