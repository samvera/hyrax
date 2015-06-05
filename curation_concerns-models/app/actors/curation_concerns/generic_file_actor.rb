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

    # in order to avoid two saves in a row, create_metadata does not save the file by default.
    # it is typically used in conjunction with create_content, which does do a save.
    # If you want to save when using create_metadata, you can do this:
    #   create_metadata(batch_id) { |gf| gf.save }
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
      else
        work = GenericWork.find(work_id)
        copy_visibility(work, generic_file)
      end
      generic_file.generic_work = work
      yield(generic_file) if block_given?
    end

    def create_content(file, file_name, mime_type)
      generic_file.add_file(file, path: file_path, original_name: file_name, mime_type: mime_type)
      generic_file.content.versionable = true
      generic_file.label ||= file_name
      generic_file.title = [generic_file.label] if generic_file.title.blank?
      save_characterize_and_record_committer do
        if Sufia.config.respond_to?(:after_create_content)
          Sufia.config.after_create_content.call(generic_file, user)
        end
      end
    end

    def revert_content(revision_id)
      generic_file.content.restore_version(revision_id)
      generic_file.content.create_version
      save_characterize_and_record_committer do
        if Sufia.config.respond_to?(:after_revert_content)
          Sufia.config.after_revert_content.call(generic_file, user, revision_id)
        end
      end
    end

    def update_content(file)
      generic_file.add_file(file, path: file_path, original_name: file.original_filename, mime_type: file.content_type)
      save_characterize_and_record_committer do
        if Sufia.config.respond_to?(:after_update_content)
          Sufia.config.after_update_content.call(generic_file, user)
        end
      end
    end

    def update_metadata(model_attributes, all_attributes)
      update_visibility(all_attributes)
      model_attributes.delete(:visibility)  # Applying this attribute is handled by update_visibility
      generic_file.attributes = model_attributes
      generic_file.date_modified = DateTime.now
      remove_from_feature_works if generic_file.visibility_changed? && !generic_file.public?
      save do
        if Sufia.config.respond_to?(:after_update_metadata)
          Sufia.config.after_update_metadata.call(generic_file, user)
        end
      end
    end

    def destroy
      generic_file.destroy
      if Sufia.config.respond_to?(:after_destroy)
        Sufia.config.after_destroy.call(generic_file.id, user)
      end
    end

    # Saves the generic file, queues a job to characterize it, and records the committer.
    # Takes a block which is run if the save was successful.
    def save_characterize_and_record_committer
      save do
        push_characterize_job
        Sufia::VersioningService.create(generic_file.content, user)
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

    def file_path
      'content'.freeze
    end

    # This method can be overridden in case there is a custom approach for visibility (e.g. embargo)
    def update_visibility(attributes)
      interpret_visibility(attributes)  # relies on CurationConcerns::ManagesEmbargoesActor to interpret and apply visibility
    end

    private

    def remove_from_feature_works
      featured_work = FeaturedWork.find_by_generic_file_id(generic_file.id)
      featured_work.destroy unless featured_work.nil?
    end

    # copy visibility from source_concern to destination_concern
    def copy_visibility(source_concern, destination_concern)
      destination_concern.visibility =  source_concern.visibility
    end
  end
end

