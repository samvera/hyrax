module CurationConcerns
  # Actions are decoupled from controller logic so that they may be called from a controller or a background job.
  class FileSetActor
    include CurationConcerns::ManagesEmbargoesActor

    attr_reader :file_set, :user, :attributes, :curation_concern

    def initialize(file_set, user)
      # we're setting attributes and curation_concern to bridge the difference
      # between CurationConcerns::FileSetActor and ManagesEmbargoesActor
      @curation_concern = file_set
      @file_set = file_set
      @user = user
    end

    # Adds the appropriate metadata, visibility and relationships to file_set
    #
    # *Note*: In past versions of Sufia this method did not perform a save because it is mainly used in conjunction with
    # create_content, which also performs a save.  However, due to the relationship between Hydra::PCDM objects,
    # we have to save both the parent work and the file_set in order to record the "metadata" relationship
    # between them.
    # @param [String] upload_set_id id of the batch of files that the file was uploaded with
    # @param [ActiveFedora::Base] work the parent work that will contain the file_set.
    # @param [Hash] file_set specifying the visibility, lease and/or embargo of the file set.  If you don't provide at least one of visibility, embargo_release_date or lease_expiration_date, visibility will be copied from the parent.

    def create_metadata(upload_set_id, work, file_set_params = {})
      file_set.apply_depositor_metadata(user)
      now = CurationConcerns::TimeService.time_in_utc
      file_set.date_uploaded = now
      file_set.date_modified = now
      file_set.creator = [user.user_key]

      if upload_set_id && file_set.respond_to?(:upload_set_id=)
        UploadSet.create(id: upload_set_id) unless UploadSet.exists?(upload_set_id)
        file_set.upload_set_id = upload_set_id
      else
        ActiveFedora::Base.logger.warn 'unable to find UploadSet to attach to'
      end

      if assign_visibility?(file_set_params)
        interpret_visibility file_set_params
      end
      # TODO: Why do we need to check if work is nil? Shoudn't that raise an error?
      attach_file_to_work(work, file_set, file_set_params) if work
      yield(file_set) if block_given?
    end

    # Puts the uploaded content into a staging directory. Then kicks off a
    # job to characterize and create derivatives with this on disk variant.
    # Simultaneously moving a preservation copy to the repostiory.
    # TODO: create a job to monitor this directory and prune old files that
    # have made it to the repo
    # @param [ActionDigest::HTTP::UploadedFile, Tempfile] file the file uploaded by the user.
    def create_content(file)
      file_set.label ||= file.original_filename
      file_set.title = [file_set.label] if file_set.title.blank?
      return false unless file_set.save

      working_file = copy_file_to_working_directory(file, file_set.id)
      IngestFileJob.perform_later(file_set.id, working_file, file.content_type, user.user_key)
      make_derivative(file_set.id, working_file)
      true
    end

    def revert_content(revision_id)
      file_set.original_file.restore_version(revision_id)

      return false unless file_set.save

      CurationConcerns::VersioningService.create(file_set.original_file, user)

      # Retrieve a copy of the orginal file from the repository
      working_file = copy_repository_resource_to_working_directory(file_set)
      make_derivative(file_set.id, working_file)

      CurationConcerns.config.callback.run(:after_revert_content, file_set, user, revision_id)
      true
    end

    def update_content(file)
      working_file = copy_file_to_working_directory(file, file_set.id)
      IngestFileJob.perform_later(file_set.id, working_file, file.content_type, user.user_key)
      make_derivative(file_set.id, working_file)
      CurationConcerns.config.callback.run(:after_update_content, file_set, user)
      true
    end

    def update_metadata(model_attributes, all_attributes)
      update_visibility(all_attributes)
      model_attributes.delete(:visibility) # Applying this attribute is handled by update_visibility
      file_set.attributes = model_attributes
      file_set.date_modified = CurationConcerns::TimeService.time_in_utc
      save do
        CurationConcerns.config.callback.run(:after_update_metadata, file_set, user)
      end
    end

    def destroy
      file_set.destroy
      # TODO: need to mend the linked list of proxies (possibly wrap with a lock)
      CurationConcerns.config.callback.run(:after_destroy, file_set.id, user)
    end

    private

      def make_derivative(file_set_id, working_file)
        CharacterizeJob.perform_later(file_set_id, working_file)
      end

      # @param [ActionDispatch::Http::UploadedFile] file
      # @param [String] id the identifer
      # @return [String] path of the working file
      def copy_file_to_working_directory(file, id)
        copy_stream_to_working_directory(id, file.original_filename, file)
      end

      # @param [FileSet] file_set the resource
      # @return [String] path of the working file
      def copy_repository_resource_to_working_directory(file_set)
        file = file_set.original_file
        copy_stream_to_working_directory(file_set.id, file.original_name, StringIO.new(file.content))
      end

      # @param [String] id the identifer
      # @param [String] name the file name
      # @param [#read] stream the stream to copy to the working directory
      # @return [String] path of the working file
      def copy_stream_to_working_directory(id, name, stream)
        working_path = full_filename(id, name)
        FileUtils.mkdir_p(File.dirname(working_path))
        IO.copy_stream(stream, working_path)
        working_path
      end

      def full_filename(id, original_name)
        pair = id.scan(/..?/).first(4)
        File.join(CurationConcerns.config.working_path, *pair, original_name)
      end

      # Takes an optional block and executes the block if the save was successful.
      # returns false if the save was unsuccessful
      def save
        save_tries = 0
        begin
          return false unless file_set.save
        rescue RSolr::Error::Http => error
          ActiveFedora::Base.logger.warn "CurationConcerns::FileSetActor#save Caught RSOLR error #{error.inspect}"
          save_tries += 1
          # fail for good if the tries is greater than 3
          raise error if save_tries >= 3
          sleep 0.01
          retry
        end
        yield if block_given?
        true
      end

      # Adds a FileSet to the work using ore:Aggregations.
      # Locks to ensure that only one process is operating on
      # the list at a time.
      def attach_file_to_work(work, file_set, file_set_params)
        acquire_lock_for(work.id) do
          # Ensure we have an up-to-date copy of the members association, so
          # that we append to the end of the list.
          work.reload unless work.new_record?
          unless assign_visibility?(file_set_params)
            copy_visibility(work, file_set)
          end
          work.ordered_members << file_set
          # Save the work so the association between the work and the file_set is persisted (head_id)
          work.save
        end
      end

      def acquire_lock_for(lock_key, &block)
        lock_manager.lock(lock_key, &block)
      end

      def lock_manager
        @lock_manager ||= CurationConcerns::LockManager.new(
          CurationConcerns.config.lock_time_to_live,
          CurationConcerns.config.lock_retry_count,
          CurationConcerns.config.lock_retry_delay)
      end

      def assign_visibility?(file_set_params = {})
        !((file_set_params || {}).keys & %w(visibility embargo_release_date lease_expiration_date)).empty?
      end

      # This method can be overridden in case there is a custom approach for visibility (e.g. embargo)
      def update_visibility(attributes)
        interpret_visibility(attributes) # relies on CurationConcerns::ManagesEmbargoesActor to interpret and apply visibility
      end

      # copy visibility from source_concern to destination_concern
      def copy_visibility(source_concern, destination_concern)
        destination_concern.visibility =  source_concern.visibility
      end
  end
end
