
class AuditJob < Struct.new(:user_id, :genericfile_id, :ds_id, :version_id)
  PASS = 'Passing Audit Run'
  FAIL = 'Failing Audit Run'

  def perform

    generic_file = GenericFile.find(genericfile_id)
    if (generic_file)    
      data_stream =  generic_file.datastreams[ds_id]
      if (data_stream)

        logger.info "Data Stream for audit = #{data_stream.inspect}"
        version =  data_stream.versions.select { |v| v.versionID == version_id}.first
        log = GenericFile.run_audit(version)
        

        # look up the user for sending the message to
        if (user_id) 
          user = User.find(user_id)
          logger.info "User = #{user.inspect}"
          job_user = User.where(login:"audituser").first
          job_user = User.create(login:"audituser", email:"auditemail") unless job_user
  
          #send the user a message about the audit
          # todo do we want to do this on failing only?
          message = "The audit run at #{log.created_at} for #{log.pid}:#{log.dsid}:#{log.version} was "
          message = message + (log.pass == 1 ? "passing." : "failing.")
          subject = (log.pass == 1 ? PASS : FAIL)
          logger.info "Sending message #{message} to user #{user.inspect}"
          recipt = job_user.send_message(user, message, subject)
        end
      else
        logger.warn "No data stream for audit!!!!! pid: #{ genericfile_id} dsid: #{dsid}"
      end
    else
      logger.warn "No generic file for data stream audit!!!!! pid: #{ genericfile_id} dsid: #{dsid}"
    end
   
  end
    
end
