module Hyrax
  module Actors
    # Actions are decoupled from controller logic so that they may be called from a controller or a background job.
    class FileSetActor
      include Lockable
      attr_reader :file_set, :user, :attributes

      def initialize(file_set, user)
        @file_set = file_set
        @user = user
      end

      # Adds the appropriate metadata, visibility and relationships to file_set
      # @note In past versions of Hyrax this method did not perform a save because it is mainly used in conjunction with
      #   create_content, which also performs a save.  However, due to the relationship between Hydra::PCDM objects,
      #   we have to save both the parent work and the file_set in order to record the "metadata" relationship between them.
      # @param [Hash] file_set_params specifying the visibility, lease and/or embargo of the file set.
      #   Without visibility, embargo_release_date or lease_expiration_date, visibility will be copied from the parent.
      def create_metadata(file_set_params = {})
        file_set.apply_depositor_metadata(user)
        now = TimeService.time_in_utc
        file_set.date_uploaded = now
        file_set.date_modified = now
        file_set.creator = [user.user_key]
        Actors::ActorStack.new(file_set, ability, [InterpretVisibilityActor]).create(file_set_params) if assign_visibility?(file_set_params)
        yield(file_set) if block_given?
      end

      # Called from AttachFilesActor, FileSetsController, AttachFilesToWorkJob, ImportURLJob, IngestLocalFileJob
      # @param [File, ActionDigest::HTTP::UploadedFile, Tempfile] file the file uploaded by the user.
      # @param [String] relation ('original_file')
      # @param [Boolean] asynchronous (true) set to false if you don't want to launch a new background job.
      def create_content(file, relation = 'original_file', asynchronous = true)
        # If the file set doesn't have a title or label assigned, set a default.
        file_set.label ||= file.respond_to?(:original_filename) ? file.original_filename : ::File.basename(file)
        file_set.title = [file_set.label] if file_set.title.blank?
        return false unless file_set.save # Need to save the file_set in order to get an id
        build_file_actor(relation).ingest_file(file, asynchronous)
        true
      end

      # Adds a FileSet to the work using ore:Aggregations.
      # Locks to ensure that only one process is operating on the list at a time.
      def attach_file_to_work(work, file_set_params = {})
        acquire_lock_for(work.id) do
          # Ensure we have an up-to-date copy of the members association, so that we append to the end of the list.
          work.reload unless work.new_record?
          copy_visibility(work, file_set) unless assign_visibility?(file_set_params)
          work.ordered_members << file_set
          set_representative(work, file_set)
          set_thumbnail(work, file_set)
          # Save the work so the association between the work and the file_set is persisted (head_id)
          # NOTE: the work may not be valid, in which case this save doesn't do anything.
          work.save
        end
      end

      # @param [String] revision_id the revision to revert to
      # @param [String] relation ('original_file')
      def revert_content(revision_id, relation = 'original_file')
        return false unless build_file_actor(relation).revert_to(revision_id)
        Hyrax.config.callback.run(:after_revert_content, file_set, user, revision_id)
        true
      end

      # @param [File, ActionDigest::HTTP::UploadedFile, Tempfile] file the file uploaded by the user.
      # @param [String] relation ('original_file')
      def update_content(file, relation = 'original_file')
        build_file_actor(relation).ingest_file(file, true)
        Hyrax.config.callback.run(:after_update_content, file_set, user)
        true
      end

      def update_metadata(attributes)
        stack = Actors::ActorStack.new(file_set,
                                       ability,
                                       [InterpretVisibilityActor, BaseActor])
        stack.update(attributes)
      end

      def destroy
        unlink_from_work
        file_set.destroy
        Hyrax.config.callback.run(:after_destroy, file_set.id, user)
      end

      def file_actor_class
        Hyrax::Actors::FileActor
      end

      # Spawns async job to attach file to fileset
      # @param [#to_s] url
      def import_url(url)
        file_set.update(import_url: url.to_s)
        operation = Hyrax::Operation.create!(user: user, operation_type: "Attach File")
        ImportUrlJob.perform_later(file_set, operation)
      end

      private

        def ability
          @ability ||= ::Ability.new(user)
        end

        def build_file_actor(relation)
          file_actor_class.new(file_set, relation, user)
        end

        # Takes an optional block and executes the block if the save was successful.
        # @return [Boolean] false if the save was unsuccessful
        def save
          on_retry = ->(exception, _, _, _) { ActiveFedora::Base.logger.warn "Hyrax::Actors::FileSetActor#save Caught RSOLR error #{exception.inspect}" }
          Retriable.retriable on: RSolr::Error::Http, on_retry: on_retry, tries: 4, base_interval: 0.01 do
            return false unless file_set.save
          end
          yield if block_given?
          true
        end

        def assign_visibility?(file_set_params = {})
          !((file_set_params || {}).keys.map(&:to_s) & %w(visibility embargo_release_date lease_expiration_date)).empty?
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
          # Must clear the thumbnail_id and representative_id fields on the work and force it to be re-solrized.
          # Although ActiveFedora clears the children nodes it leaves those fields in Solr populated.
          work.thumbnail = nil if work.thumbnail_id == file_set.id
          work.representative = nil if work.representative_id == file_set.id
          work.save!
        end
    end
  end
end
