# frozen_string_literal: true
module Hyrax
  module Actors
    # Actions are decoupled from controller logic so that they may be called from a controller or a background job.
    class FileSetActor # rubocop:disable Metrics/ClassLength
      include Lockable
      attr_reader :file_set, :user, :attributes, :use_valkyrie

      def initialize(file_set, user, use_valkyrie: Hyrax.config.query_index_from_valkyrie)
        @use_valkyrie = use_valkyrie
        @file_set = file_set
        @user = user
      end

      # @!group Asynchronous Operations

      # Spawns asynchronous IngestJob unless ingesting from URL
      # Called from FileSetsController, AttachFilesToWorkJob, IngestLocalFileJob, ImportUrlJob
      # @param [Hyrax::UploadedFile, File] file the file uploaded by the user
      # @param [Symbol, #to_s] relation
      # @return [IngestJob, FalseClass] false on failure, otherwise the queued job
      def create_content(file, relation = :original_file, from_url: false)
        # If the file set doesn't have a title or label assigned, set a default.
        file_set.label ||= label_for(file)
        file_set.title = [file_set.label] if file_set.title.blank?
        @file_set = perform_save(file_set)
        return false unless file_set
        if from_url
          # If ingesting from URL, don't spawn an IngestJob; instead
          # reach into the FileActor and run the ingest with the file instance in
          # hand. Do this because we don't have the underlying UploadedFile instance
          file_actor = build_file_actor(relation)
          file_actor.ingest_file(wrapper!(file: file, relation: relation))
          parent = parent_for(file_set: file_set)
          VisibilityCopyJob.perform_later(parent)
          InheritPermissionsJob.perform_later(parent)
        else
          IngestJob.perform_later(wrapper!(file: file, relation: relation))
        end
      end

      # Spawns asynchronous IngestJob with user notification afterward
      # @param [Hyrax::UploadedFile, File, ActionDigest::HTTP::UploadedFile] file the file uploaded by the user
      # @param [Symbol, #to_s] relation
      # @return [IngestJob] the queued job
      def update_content(file, relation = :original_file)
        IngestJob.perform_later(wrapper!(file: file, relation: relation), notification: true)
      end
      # @!endgroup

      # Adds the appropriate metadata, visibility and relationships to file_set
      # @note In past versions of Hyrax this method did not perform a save because it is mainly used in conjunction with
      #   create_content, which also performs a save.  However, due to the relationship between Hydra::PCDM objects,
      #   we have to save both the parent work and the file_set in order to record the "metadata" relationship between them.
      # @param [Hash] file_set_params specifying the visibility, lease and/or embargo of the file set.
      #   Without visibility, embargo_release_date or lease_expiration_date, visibility will be copied from the parent.
      def create_metadata(file_set_params = {})
        file_set.depositor = depositor_id(user)
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

      # Locks to ensure that only one process is operating on the list at a time.
      def attach_to_work(work, file_set_params = {})
        acquire_lock_for(work.id) do
          # Ensure we have an up-to-date copy of the members association, so that we append to the end of the list.
          if valkyrie_object?(work)
            attach_to_valkyrie_work(work, file_set_params)
          else
            attach_to_af_work(work, file_set_params)
          end
          Hyrax.config.callback.run(:after_create_fileset, file_set, user, warn: false)
        end
      end
      alias attach_file_to_work attach_to_work
      deprecation_deprecate attach_file_to_work: "use attach_to_work instead"

      def attach_to_valkyrie_work(work, file_set_params)
        work = Hyrax.query_service.find_by(id: work.id) unless work.new_record
        file_set.visibility = work.visibility unless assign_visibility?(file_set_params)
        fs = Hyrax.persister.save(resource: file_set)
        Hyrax.publisher.publish('object.metadata.updated', object: fs, user: user)
        work.member_ids << fs.id
        work.representative_id = fs.id if work.representative_id.blank?
        work.thumbnail_id = fs.id if work.thumbnail_id.blank?
        # Save the work so the association between the work and the file_set is persisted (head_id)
        # NOTE: the work may not be valid, in which case this save doesn't do anything.
        Hyrax.persister.save(resource: work)
        Hyrax.publisher.publish('object.metadata.updated', object: work, user: user)
      end

      # Adds a FileSet to the work using ore:Aggregations.
      def attach_to_af_work(work, file_set_params)
        work.reload unless work.new_record?
        file_set.visibility = work.visibility unless assign_visibility?(file_set_params)
        work.ordered_members << file_set
        work.representative = file_set if work.representative_id.blank?
        work.thumbnail = file_set if work.thumbnail_id.blank?
        # Save the work so the association between the work and the file_set is persisted (head_id)
        # NOTE: the work may not be valid, in which case this save doesn't do anything.
        work.save
      end

      # @param [String] revision_id the revision to revert to
      # @param [Symbol, #to_sym] relation
      # @return [Boolean] true on success, false otherwise
      def revert_content(revision_id, relation = :original_file)
        return false unless build_file_actor(relation).revert_to(revision_id)
        Hyrax.config.callback.run(:after_revert_content, file_set, user, revision_id, warn: false)
        true
      end

      def update_metadata(attributes)
        env = Actors::Environment.new(file_set, ability, attributes)
        CurationConcern.file_set_update_actor.update(env)
      end

      def destroy
        unlink_from_work
        file_set.destroy
        Hyrax.config.callback.run(:after_destroy, file_set.id, user, warn: false)
      end

      class_attribute :file_actor_class
      self.file_actor_class = Hyrax::Actors::FileActor

      private

      def ability
        @ability ||= ::Ability.new(user)
      end

      # @param file_set [FileSet]
      # @return [ActiveFedora::Base]
      def parent_for(file_set:)
        file_set.parent
      end

      def build_file_actor(relation)
        fs = use_valkyrie ? file_set.valkyrie_resource : file_set
        file_actor_class.new(fs, relation, user, use_valkyrie: use_valkyrie)
      end

      # uses create! because object must be persisted to serialize for jobs
      def wrapper!(file:, relation:)
        JobIoWrapper.create_with_varied_file_handling!(user: user, file: file, relation: relation, file_set: file_set)
      end

      # For the label, use the original_filename or original_name if it's there.
      # If the file was imported via URL, parse the original filename.
      # If all else fails, use the basename of the file where it sits.
      # @note This is only useful for labeling the file_set, because of the recourse to import_url
      def label_for(file)
        if file.is_a?(Hyrax::UploadedFile) # filename not present for uncached remote file!
          file.uploader.filename.presence || File.basename(Addressable::URI.unencode(file.file_url))
        elsif file.respond_to?(:original_name) # e.g. Hydra::Derivatives::IoDecorator
          file.original_name
        elsif file_set.import_url.present?
          # This path is taken when file is a Tempfile (e.g. from ImportUrlJob)
          File.basename(Addressable::URI.unencode(file.file_url))
        elsif file.respond_to?(:original_filename) # e.g. Rack::Test::UploadedFile
          file.original_filename
        else
          File.basename(file)
        end
      end

      def assign_visibility?(file_set_params = {})
        !((file_set_params || {}).keys.map(&:to_s) & %w[visibility embargo_release_date lease_expiration_date]).empty?
      end

      # replaces file_set.apply_depositor_metadata(user)from hydra-access-controls so depositor doesn't automatically get edit access
      def depositor_id(depositor)
        depositor.respond_to?(:user_key) ? depositor.user_key : depositor
      end

      # Must clear the fileset from the thumbnail_id, representative_id and rendering_ids fields on the work
      #   and force it to be re-solrized.
      # Although ActiveFedora clears the children nodes it leaves those fields in Solr populated.
      # rubocop:disable Metrics/CyclomaticComplexity
      def unlink_from_work
        work = parent_for(file_set: file_set)
        return unless work && (work.thumbnail_id == file_set.id || work.representative_id == file_set.id || work.rendering_ids.include?(file_set.id))
        work.thumbnail = nil if work.thumbnail_id == file_set.id
        work.representative = nil if work.representative_id == file_set.id
        work.rendering_ids -= [file_set.id]
        work.save!
      end

      # switches between using valkyrie to save or active fedora to save
      def perform_save(object)
        obj_to_save = object_to_act_on(object)
        if valkyrie_object?(obj_to_save)
          saved_resource = Hyrax.persister.save(resource: obj_to_save)
          # return the same type of object that was passed in
          saved_object_to_return = valkyrie_object?(object) ? saved_resource : Wings::ActiveFedoraConverter.new(resource: saved_resource).convert
        else
          obj_to_save.save
          saved_object_to_return = obj_to_save
        end
        saved_object_to_return
      end

      # if passed a resource or if use_valkyrie==true, object to act on is the valkyrie resource
      def object_to_act_on(object)
        return object if valkyrie_object?(object)
        use_valkyrie ? object.valkyrie_resource : object
      end

      # determine if the object is a valkyrie resource
      def valkyrie_object?(object)
        object.is_a? Valkyrie::Resource
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/CyclomaticComplexity
    end
  end
end
