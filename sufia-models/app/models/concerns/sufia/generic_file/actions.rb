module Sufia::GenericFile
  # Actions are decoupled from controller logic so that they may be called from a controller or a background job.
  module Actions
    def self.create_metadata(generic_file, user, batch_id)
      generic_file.apply_depositor_metadata(user)
      generic_file.date_uploaded = Date.today
      generic_file.date_modified = Date.today
      generic_file.creator = user.name

      if batch_id
        generic_file.add_relationship("isPartOf", "info:fedora/#{Sufia::Noid.namespaceize(batch_id)}")
      else
        logger.warn "unable to find batch to attach to"
      end
      yield(generic_file) if block_given?
    end

    def self.create_content(generic_file, file, file_name, dsid, user)
      generic_file.add_file(file, dsid, file_name)

      save_tries = 0
      begin
        return false unless generic_file.save
      rescue RSolr::Error::Http => error
        logger.warn "GenericFilesController::create_and_save_generic_file Caught RSOLR error #{error.inspect}"
        save_tries+=1
        # fail for good if the tries is greater than 3
        raise error if save_tries >=3
        sleep 0.01
        retry
      end

      generic_file.record_version_committer(user)
      if Sufia.config.respond_to?(:after_create_content)
        Sufia.config.after_create_content.call(generic_file, user)
      end
      true
    end

    def self.revert_content(generic_file, revision_id, datastream_id, current_user)
      revision = generic_file.content.get_version(revision_id)
      generic_file.add_file(revision.content, datastream_id, revision.label)
    end

    def self.update_content(generic_file, file, datastream_id, current_user)
      generic_file.add_file(file, datastream_id, file.original_filename)
    end

    def self.virus_check(file)
      path = file.is_a?(String) ? file : file.path
      unless defined?(ClamAV)
        logger.warn "Virus checking disabled, #{path} not checked"
        return
      end
      scan_result = ClamAV.instance.scanfile(path)
      raise Sufia::VirusFoundError.new("A virus was found in #{path}: #{scan_result}") unless scan_result == 0
    end
  end
end
