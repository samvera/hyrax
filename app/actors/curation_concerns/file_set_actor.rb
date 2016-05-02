module CurationConcerns
  # Actions are decoupled from controller logic so that they may be called from a controller or a background job.
  class FileSetActor
    include CurationConcerns::Lockable

    attr_reader :file_set, :user, :attributes

    def initialize(file_set, user)
      @file_set = file_set
      @user = user
    end

    # Adds the appropriate metadata, visibility and relationships to file_set
    #
    # *Note*: In past versions of Sufia this method did not perform a save because it is mainly used in conjunction with
    # create_content, which also performs a save.  However, due to the relationship between Hydra::PCDM objects,
    # we have to save both the parent work and the file_set in order to record the "metadata" relationship
    # between them.
    # @param [ActiveFedora::Base] work the parent work that will contain the file_set.
    # @param [Hash] file_set specifying the visibility, lease and/or embargo of the file set.  If you don't provide at least one of visibility, embargo_release_date or lease_expiration_date, visibility will be copied from the parent.

    def create_metadata(work, file_set_params = {})
      file_set.apply_depositor_metadata(user)
      now = CurationConcerns::TimeService.time_in_utc
      file_set.date_uploaded = now
      file_set.date_modified = now
      file_set.creator = [user.user_key]

      ActorStack.new(file_set, user, [InterpretVisibilityActor]).create(file_set_params) if assign_visibility?(file_set_params)
      attach_file_to_work(work, file_set, file_set_params) if work
      yield(file_set) if block_given?
    end

    # @param [File, ActionDigest::HTTP::UploadedFile, Tempfile] file the file uploaded by the user.
    # @param [String] relation ('original_file')
    def create_content(file, relation = 'original_file')
      # If the file set doesn't have a title or label assigned, set a default.
      file_set.label ||= file.respond_to?(:original_filename) ? file.original_filename : ::File.basename(file)
      file_set.title = [file_set.label] if file_set.title.blank?

      # Need to save the file_set in order to get an id
      return false unless file_set.save

      file_actor_class.new(file_set, relation, user).ingest_file(file)
      true
    end

    # @param [String] revision_id the revision to revert to
    # @param [String] relation ('original_file')
    def revert_content(revision_id, relation = 'original_file')
      file_actor = file_actor_class.new(file_set, relation, user)
      if file_actor.revert_to(revision_id)
        CurationConcerns.config.callback.run(:after_revert_content, file_set, user, revision_id)
        true
      else
        false
      end
    end

    # @param [File, ActionDigest::HTTP::UploadedFile, Tempfile] file the file uploaded by the user.
    # @param [String] relation ('original_file')
    def update_content(file, relation = 'original_file')
      file_actor_class.new(file_set, relation, user).ingest_file(file)
      CurationConcerns.config.callback.run(:after_update_content, file_set, user)
      true
    end

    def update_metadata(attributes)
      stack = ActorStack.new(file_set,
                             user,
                             [InterpretVisibilityActor, BaseActor])
      stack.update(attributes)
    end

    def destroy
      unlink_from_work
      file_set.destroy
      CurationConcerns.config.callback.run(:after_destroy, file_set.id, user)
    end

    def file_actor_class
      CurationConcerns::FileActor
    end

    private

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
          set_representative(work, file_set)
          set_thumbnail(work, file_set)

          # Save the work so the association between the work and the file_set is persisted (head_id)
          work.save
        end
        CurationConcerns.config.callback.run(:after_create_fileset, file_set, user)
      end

      def assign_visibility?(file_set_params = {})
        !((file_set_params || {}).keys & %w(visibility embargo_release_date lease_expiration_date)).empty?
      end

      # copy visibility from source_concern to destination_concern
      def copy_visibility(source_concern, destination_concern)
        destination_concern.visibility =  source_concern.visibility
      end

      def set_representative(work, file_set)
        return unless work.representative_id.blank?
        work.representative = file_set
      end

      def set_thumbnail(work, file_set)
        return unless work.thumbnail_id.blank?
        work.thumbnail = file_set
      end

      def unlink_from_work
        work = file_set.parent
        return unless work && (work.thumbnail_id == file_set.id || work.representative_id == file_set.id)
        # This is required to clear the thumbnail_id and representative_id
        # fields on the work and force it to be re-solrized. Although
        # ActiveFedora clears the children nodes it leaves the work's
        # thumbnail_id and representative_id fields in Solr populated.
        work.thumbnail = nil if work.thumbnail_id == file_set.id
        work.representative = nil if work.representative_id == file_set.id
        work.save!
      end
  end
end
