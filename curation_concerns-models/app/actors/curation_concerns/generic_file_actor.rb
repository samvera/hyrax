module CurationConcerns
  # Actions are decoupled from controller logic so that they may be called from a controller or a background job.
  class GenericFileActor
    include CurationConcerns::ManagesEmbargoesActor

    attr_reader :generic_file, :user, :attributes, :curation_concern

    def initialize(generic_file, user)
      # we're setting attributes and curation_concern to bridge the difference
      # between Sufia::GenericFile::Actor and ManagesEmbargoesActor
      @curation_concern = generic_file
      @generic_file = generic_file
      @user = user
    end

    # Adds the appropriate metadata, visibility and relationships to generic_file
    #
    # *Note*: In past versions of Sufia this method did not perform a save because it is mainly used in conjunction with
    # create_content, which also performs a save.  However, due to the relationship between Hydra::PCDM objects,
    # we have to save both the parent work and the generic_file in order to record the "metadata" relationship
    # between them.
    # @param [String] batch_id id of the batch that the file was uploaded within
    # @param [String] work_id id of the parent work that will contain the generic_file.  If you don't provide a work_id, a parent work will be created for you.

    def create_metadata(batch_id, work_id)
      generic_file.apply_depositor_metadata(user)
      time_in_utc = DateTime.now.new_offset(0)
      generic_file.date_uploaded = time_in_utc
      generic_file.date_modified = time_in_utc
      generic_file.creator = [user.name]

      if batch_id
        generic_file.batch_id = batch_id
      else
        ActiveFedora::Base.logger.warn "unable to find batch to attach to"
      end

      if work_id.blank?
        work = GenericWork.new
        work.apply_depositor_metadata(user)
        work.date_uploaded = time_in_utc
        work.date_modified = time_in_utc
        work.creator = [user.name]
        work.save
      else
        work = GenericWork.find(work_id)
        copy_visibility(work, generic_file)
      end
      Hydra::Works::AddGenericFileToGenericWork.call(work, generic_file)
      yield(generic_file) if block_given?
    end

    def create_content(file, file_name, mime_type)
      # Tell UploadFileToGenericFile service to skip versioning because versions will be minted by VersionCommitter (called by save_characterize_and_record_committer) when necessary
      Hydra::Works::UploadFileToGenericFile.call(generic_file, file.path, versioning: false, mime_type: mime_type, original_name: file_name)
      generic_file.label ||= file_name
      generic_file.title = [generic_file.label] if generic_file.title.blank?
      save_characterize_and_record_committer do
        if CurationConcerns.config.respond_to?(:after_create_content)
          CurationConcerns.config.after_create_content.call(generic_file, user)
        end
      end
    end

    def revert_content(revision_id)
      generic_file.original_file.restore_version(revision_id)
      save_characterize_and_record_committer do
        if CurationConcerns.config.respond_to?(:after_revert_content)
          CurationConcerns.config.after_revert_content.call(generic_file, user, revision_id)
        end
      end
    end

    def update_content(file)
      # Tell UploadFileToGenericFile service to skip versioning because versions will be minted by VersionCommitter (called by save_characterize_and_record_committer) when necessary
      Hydra::Works::UploadFileToGenericFile.call(generic_file, file.path, versioning: false, mime_type: file.content_type, original_name: file.original_filename)
      save_characterize_and_record_committer do
        if CurationConcerns.config.respond_to?(:after_update_content)
          CurationConcerns.config.after_update_content.call(generic_file, user)
        end
      end
    end

    def update_metadata(model_attributes, all_attributes)
      update_visibility(all_attributes)
      model_attributes.delete(:visibility)  # Applying this attribute is handled by update_visibility
      generic_file.attributes = model_attributes
      generic_file.date_modified = DateTime.now
      save do
        if CurationConcerns.config.respond_to?(:after_update_metadata)
          CurationConcerns.config.after_update_metadata.call(generic_file, user)
        end
      end
    end

    def destroy
      generic_file.destroy
      if CurationConcerns.config.respond_to?(:after_destroy)
        CurationConcerns.config.after_destroy.call(generic_file.id, user)
      end
    end

    # Saves the generic file, queues a job to characterize it, and records the committer.
    # Takes a block which is run if the save was successful.
    def save_characterize_and_record_committer
      save do
        push_characterize_job
        CurationConcerns::VersioningService.create(generic_file.original_file, user)
        yield if block_given?
      end
    end

    # Takes an optional block and executes the block if the save was successful.
    # returns false if the save was unsuccessful
    def save
      save_tries = 0
      begin
        return false unless generic_file.save
      rescue RSolr::Error::Http => error
        ActiveFedora::Base.logger.warn "Sufia::GenericFile::Actor#save Caught RSOLR error #{error.inspect}"
        save_tries+=1
        # fail for good if the tries is greater than 3
        raise error if save_tries >=3
        sleep 0.01
        retry
      end
      yield if block_given?
      true
    end

    def push_characterize_job
      Sufia.queue.push(CharacterizeJob.new(@generic_file.id))
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

    protected

    # This method can be overridden in case there is a custom approach for visibility (e.g. embargo)
    def update_visibility(attributes)
      interpret_visibility(attributes)  # relies on CurationConcerns::ManagesEmbargoesActor to interpret and apply visibility
    end

    private

    # copy visibility from source_concern to destination_concern
    def copy_visibility(source_concern, destination_concern)
      destination_concern.visibility =  source_concern.visibility
    end
  end
end

