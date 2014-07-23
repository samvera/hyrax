module Sufia::GenericFile
  # Actions are decoupled from controller logic so that they may be called from a controller or a background job.
  class Actor

    attr_reader :generic_file, :user

    def initialize(generic_file, user)
      @generic_file = generic_file
      @user = user
    end

    # in order to avoid two saves in a row, create_metadata does not save the file by default.
    # it is typically used in conjunction with create_content, which does do a save.
    # If you want to save when using create_metadata, you can do this:
    #   create_metadata(batch_id) { |gf| gf.save }
    def create_metadata(batch_id)
      generic_file.apply_depositor_metadata(user)
      generic_file.date_uploaded = Date.today
      generic_file.date_modified = Date.today
      generic_file.creator = [user.name]

      if batch_id
        generic_file.add_relationship("isPartOf", "info:fedora/#{Sufia::Noid.namespaceize(batch_id)}")
      else
        ActiveFedora::Base.logger.warn "unable to find batch to attach to"
      end
      yield(generic_file) if block_given?
    end

    def create_content(file, file_name, dsid)
      generic_file.add_file(file, dsid, file_name)
      save_characterize_and_record_committer do
        if Sufia.config.respond_to?(:after_create_content)
          Sufia.config.after_create_content.call(generic_file, user)
        end
      end
    end

    def revert_content(revision_id, datastream_id)
      revision = generic_file.content.get_version(revision_id)
      generic_file.add_file(revision.content, datastream_id, revision.label)
      save_characterize_and_record_committer do
        if Sufia.config.respond_to?(:after_revert_content)
          Sufia.config.after_revert_content.call(generic_file, user, revision_id)
        end
      end
    end

    def update_content(file, datastream_id)
      generic_file.add_file(file, datastream_id, file.original_filename)
      save_characterize_and_record_committer do
        if Sufia.config.respond_to?(:after_update_content)
          Sufia.config.after_update_content.call(generic_file, user)
        end
      end
    end

    def update_metadata(attributes, visibility)
      generic_file.attributes = generic_file.sanitize_attributes(attributes)
      generic_file.visibility = visibility
      generic_file.date_modified = DateTime.now
      save_and_record_committer do
        if Sufia.config.respond_to?(:after_update_metadata)
          Sufia.config.after_update_metadata.call(generic_file, user)
        end
      end
    end

    def destroy
      pid = generic_file.pid  #Work around for https://github.com/projecthydra/active_fedora/issues/422
      generic_file.destroy
      if Sufia.config.respond_to?(:after_destroy)
        Sufia.config.after_destroy.call(pid, user)
      end
    end

    # Takes an optional block and executes the block if the save was successful.
    def save_characterize_and_record_committer
      save_and_record_committer { push_characterize_job }.tap do |val|
        yield if block_given? && val
      end
    end

    # Takes an optional block and executes the block if the save was successful.
    def save_and_record_committer
      save_tries = 0
      begin
        return false unless generic_file.save
      rescue RSolr::Error::Http => error
        ActiveFedora::Base.logger.warn "Sufia::GenericFile::Actor::save_and_record_committer Caught RSOLR error #{error.inspect}"
        save_tries+=1
        # fail for good if the tries is greater than 3
        raise error if save_tries >=3
        sleep 0.01
        retry
      end
      yield if block_given?
      generic_file.record_version_committer(user)
      true
    end

    def push_characterize_job
      Sufia.queue.push(CharacterizeJob.new(@generic_file.pid))
    end

    class << self
      def virus_check(file)
        path = file.is_a?(String) ? file : file.path
        unless defined?(ClamAV)
          ActiveFedora::Base.logger.warn "Virus checking disabled, #{path} not checked"
          return
        end
        scan_result = ClamAV.instance.scanfile(path)
        raise Sufia::VirusFoundError.new("A virus was found in #{path}: #{scan_result}") unless scan_result == 0
      end
    end
  end
end
