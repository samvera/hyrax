module CurationConcerns
  # Actions are decoupled from controller logic so that they may be called from a controller or a background job.
  class GenericFileActor
    include CurationConcerns::ManagesEmbargoesActor

    attr_reader :generic_file, :user, :attributes, :curation_concern

    def initialize(generic_file, user)
      # we're setting attributes and curation_concern to bridge the difference
      # between CurationConcerns::GenericFileActor and ManagesEmbargoesActor
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
    # @param [String] upload_set_id id of the batch of files that the file was uploaded with
    # @param [String] work_id id of the parent work that will contain the generic_file.
    # @param [Hash] generic_file_params specifying the visibility, lease and/or embargo of the generic file.  If you don't provide at least one of visibility, embargo_release_date or lease_expiration_date, visibility will be copied from the parent.

    def create_metadata(upload_set_id, work_id, generic_file_params = {})
      generic_file.apply_depositor_metadata(user)
      time_in_utc = DateTime.now.new_offset(0)
      generic_file.date_uploaded = time_in_utc
      generic_file.date_modified = time_in_utc
      generic_file.creator = [user.user_key]

      if upload_set_id && generic_file.respond_to?(:upload_set_id=)
        UploadSet.create(id: upload_set_id) unless UploadSet.exists?(upload_set_id)
        generic_file.upload_set_id = upload_set_id
      else
        ActiveFedora::Base.logger.warn 'unable to find UploadSet to attach to'
      end

      if assign_visibility?(generic_file_params)
        interpret_visibility generic_file_params
      end
      unless work_id.blank?
        work = ActiveFedora::Base.find(work_id)

        unless assign_visibility?(generic_file_params)
          copy_visibility(work, generic_file)
        end
        work.generic_files << generic_file
        # Save the work so the association between the work and the generic_file is persisted (head_id)
        work.save
      end
      yield(generic_file) if block_given?
    end

    def assign_visibility?(generic_file_params = {})
      !((generic_file_params || {}).keys & %w(visibility embargo_release_date lease_expiration_date)).empty?
    end

    def create_content(file)
      # Tell UploadFileToGenericFile service to skip versioning because versions will be minted by VersionCommitter (called by save_characterize_and_record_committer) when necessary
      Hydra::Works::UploadFileToGenericFile.call(generic_file, file, versioning: false)
      generic_file.label ||= file.original_filename
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
      Hydra::Works::UploadFileToGenericFile.call(generic_file, file, versioning: false)
      save_characterize_and_record_committer do
        if CurationConcerns.config.respond_to?(:after_update_content)
          CurationConcerns.config.after_update_content.call(generic_file, user)
        end
      end
    end

    def update_metadata(model_attributes, all_attributes)
      update_visibility(all_attributes)
      model_attributes.delete(:visibility) # Applying this attribute is handled by update_visibility
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
      CurationConcerns.config.after_destroy.call(generic_file.id, user) if CurationConcerns.config.respond_to?(:after_destroy)
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
        ActiveFedora::Base.logger.warn "CurationConcerns::GenericFileActor#save Caught RSOLR error #{error.inspect}"
        save_tries += 1
        # fail for good if the tries is greater than 3
        raise error if save_tries >= 3
        sleep 0.01
        retry
      end
      yield if block_given?
      true
    end

    def push_characterize_job
      CharacterizeJob.perform_later(@generic_file.id)
    end

    protected

      # This method can be overridden in case there is a custom approach for visibility (e.g. embargo)
      def update_visibility(attributes)
        interpret_visibility(attributes) # relies on CurationConcerns::ManagesEmbargoesActor to interpret and apply visibility
      end

    private

      # copy visibility from source_concern to destination_concern
      def copy_visibility(source_concern, destination_concern)
        destination_concern.visibility =  source_concern.visibility
      end
  end
end
