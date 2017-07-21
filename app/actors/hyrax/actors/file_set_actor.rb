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

      # @!group Asynchronous Operations

      # Spawns asynchronous IngestJob
      # Called from FileSetsController, AttachFilesToWorkJob, ImportURLJob, IngestLocalFileJob
      # @param [Hyrax::UploadedFile, File, ActionDigest::HTTP::UploadedFile] file the file uploaded by the user
      # @param [Symbol, #to_s] relation
      # @return [IngestJob, FalseClass] false on failure, otherwise the queued job
      def create_content(file, relation = :original_file)
        # If the file set doesn't have a title or label assigned, set a default.
        file_set.label ||= label_for(file)
        file_set.title = [file_set.label] if file_set.title.blank?
        return false unless file_set.save # Need to save to get an id
        IngestJob.perform_later(wrapper!(file, relation))
      end

      # Spawns asynchronous IngestJob with user notification afterward
      # @param [Hyrax::UploadedFile, File, ActionDigest::HTTP::UploadedFile] file the file uploaded by the user
      # @param [Symbol, #to_s] relation
      # @return [IngestJob] the queued job
      def update_content(file, relation = :original_file)
        IngestJob.perform_later(wrapper!(file, relation), notification: true)
      end

      # Spawns async ImportUrlJob to attach remote file to fileset
      # @param [#to_s] url
      # @return [IngestUrlJob] the queued job
      def import_url(url)
        file_set.update(import_url: url.to_s)
        operation = Hyrax::Operation.create!(user: user, operation_type: "Attach File")
        ImportUrlJob.perform_later(file_set, operation)
      end

      # @!endgroup

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
        if assign_visibility?(file_set_params)
          env = Actors::Environment.new(file_set, ability, file_set_params)
          CurationConcern.file_set_create_actor.create(env)
        end
        yield(file_set) if block_given?
      end

      # Adds a FileSet to the work using ore:Aggregations.
      # Locks to ensure that only one process is operating on the list at a time.
      def attach_to_work(work, file_set_params = {})
        acquire_lock_for(work.id) do
          # Ensure we have an up-to-date copy of the members association, so that we append to the end of the list.
          work.reload unless work.new_record?
          file_set.visibility = work.visibility unless assign_visibility?(file_set_params)
          work.ordered_members << file_set
          work.representative = file_set if work.representative_id.blank?
          work.thumbnail = file_set if work.thumbnail_id.blank?
          # Save the work so the association between the work and the file_set is persisted (head_id)
          # NOTE: the work may not be valid, in which case this save doesn't do anything.
          work.save
          Hyrax.config.callback.run(:after_create_fileset, file_set, user)
        end
      end
      alias attach_file_to_work attach_to_work
      deprecation_deprecate attach_file_to_work: "use attach_to_work instead"

      # @param [String] revision_id the revision to revert to
      # @param [Symbol, #to_sym] relation
      # @return [Boolean] true on success, false otherwise
      def revert_content(revision_id, relation = :original_file)
        return false unless build_file_actor(relation).revert_to(revision_id)
        Hyrax.config.callback.run(:after_revert_content, file_set, user, revision_id)
        true
      end

      def update_metadata(attributes)
        env = Actors::Environment.new(file_set, ability, attributes)
        CurationConcern.file_set_update_actor.update(env)
      end

      def destroy
        unlink_from_work
        file_set.destroy
        Hyrax.config.callback.run(:after_destroy, file_set.id, user)
      end

      def file_actor_class
        Hyrax::Actors::FileActor
      end

      private

        def ability
          @ability ||= ::Ability.new(user)
        end

        def build_file_actor(relation)
          file_actor_class.new(file_set, relation, user)
        end

        # uses create! because object must be persisted to serialize for jobs
        def wrapper!(file, relation)
          JobIoWrapper.create!(wrapper_params(file, relation))
        end

        # helps testing
        # @return [Hash] params for JobIoWrapper (new or create)
        def wrapper_params(file, relation)
          args = { user: user, relation: relation.to_s, file_set_id: file_set.id }
          if file.is_a?(Hyrax::UploadedFile)
            args[:uploaded_file] = file
            args[:path] = file.uploader.path
          elsif file.respond_to?(:path)
            args[:path] = file.path
            args[:original_name] = file.original_filename if file.respond_to?(:original_filename)
            args[:original_name] ||= file.original_name if file.respond_to?(:original_name)
          else
            raise "Require Hyrax::UploadedFile or File-like object, received #{file.class} object: #{file}"
          end
          args
        end

        # For the label, use the original_filename or original_name if it's there.
        # If the file was imported via URL, parse the original filename.
        # If all else fails, use the basename of the file where it sits.
        # @note This is only useful for labeling the file_set, because of the recourse to import_url
        def label_for(file)
          if file.is_a?(Hyrax::UploadedFile) # filename not present for uncached remote file!
            file.uploader.filename.present? ? file.uploader.filename : File.basename(Addressable::URI.parse(file.file_url).path)
          elsif file.respond_to?(:original_filename) # e.g. ActionDispatch::Http::UploadedFile, CarrierWave::SanitizedFile
            file.original_filename
          elsif file.respond_to?(:original_name) # e.g. Hydra::Derivatives::IoDecorator
            file.original_name
          elsif file_set.import_url.present?
            # This path is taken when file is a Tempfile (e.g. from ImportUrlJob)
            File.basename(Addressable::URI.parse(file_set.import_url).path)
          else
            File.basename(file)
          end
        end

        def assign_visibility?(file_set_params = {})
          !((file_set_params || {}).keys.map(&:to_s) & %w[visibility embargo_release_date lease_expiration_date]).empty?
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
