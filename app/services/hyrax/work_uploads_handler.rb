# frozen_string_literal: true

module Hyrax
  ##
  # @api public
  #
  # Mediates uploads to a work.
  #
  # Given an existing Work object, `#add` some set of files, then call `#attach`
  # to handle creation/attachment of File Sets, and trigger persistence of files
  # to the storage backend.
  #
  # This class provides both an interface and a concrete implementation.
  # Applications that want to handle file attachment differently (e.g. by making
  # them completely synchronous, by attaching file sets to a different work
  # attribute, by supporting another file/IO class, etc...) can use a different
  # `Handler` implementation. The only guarantee made by the _interface_ is that
  # the process of persisting the relationship between `work` and the provided
  # `files` will start when `#attach` is called.
  #
  # This base implementation accepts only `Hyrax::UploadedFile` instances and,
  # for each one, creates a `Hyrax::FileSet` with permissions matching those on
  # `work`, and appends that FileSet to `member_ids`. The `FileSet` will be
  # added in the order that the `UploadedFiles` are passed in. If the work has a
  # `nil` `representative_id` and/or `thumbnail_id`, the first `FileSet` will be
  # set to that value. An `IngestJob` will be enqueued, for each `FileSet`. When
  # all of the `files` have been processed, the work will be saved with the
  # added members. While this is happening, we take a lock on the work via
  # `Lockable` (Redis/Redlock).
  #
  # This also publishes events as required by `Hyrax.publisher`.
  #
  # @example
  #   Hyrax::WorkUploadsHandler.new(work: my_work)
  #     .add(files: [file1, file2])
  #     .attach
  #
  class WorkUploadsHandler
    include Lockable

    ##
    # @!attribute [r] files
    #   @return [Enumberable<Hyrax::UploadedFile>]
    # @!attribute [r] work
    #   @return [Hyrax::Work]
    # @!attribute [r] file_set_params
    #   @return [Enumerable<Hash>]
    attr_reader :files, :work, :file_set_params

    ##
    # @param [Hyrax::Work] work
    # @param [#save] persister the valkyrie persister to use
    def initialize(work:, persister: Hyrax.persister)
      # NOTE: this instance variable is re-loaded later in the class, to avoid locking a stale version of the work
      @work = work
      @persister = persister
    end

    ##
    # @api public
    #
    # @param [Enumerable<Hyrax::UploadedFile>] files  files to add
    #
    # @param [Enumerable<Hash>] file_set_params additional parameters for each file_set
    #
    # @return [WorkFileSetManager] self
    # @raise [ArgumentError] if any of the uploaded files are not an
    #   `UploadedFile`
    # Get rid of the word "file" in here
    # Dig into why / if we get a FileMetadata here
    def add(files:, file_set_params: [])
      validate_files(files) &&
        @files = Array.wrap(files).reject { |file| work.member_ids.include?(file.file_set_uri) }
      @file_set_params = file_set_params || []
      self
    end

    ##
    # @api public
    #
    # Create filesets for each added file, and add some additional metadata passed in file_set_params
    # Additional metadata will only be set if it is not overriden by the `file_set_args` hash, and if it is a valid part of the schema
    #
    # @return [Boolean] true if all requested files were attached
    def attach
      return true if Array.wrap(files).empty? # short circuit to avoid aquiring a lock we won't use

      event_payloads = create_file_sets(files)
      append_file_sets_to_work(file_ids: event_payloads.map { |payload| payload[:file_set_id] }, user: files.first.user)
      event_payloads.each do |payload|
        payload.delete(:job).enqueue
        Hyrax.publisher.publish('file.set.attached', file_set: Hyrax.query_service.find_by(id: payload[:file_set_id]), user: payload[:user])
      end
    end

    private

    ##
    # @api private
    def create_file_sets(files)
      files.each_with_object([]).with_index do |(file, arry), index|
        file_set = find_or_create_file_set(file, file_set_params[index] || {})
        update_file_set(file_set, file)
        arry << { file_set_id: file_set.id, user: file.user, job: ValkyrieIngestJob.new(file) }
      end
    end

    ##
    # @api private
    def append_file_sets_to_work(file_ids:, user:)
      work_id = work.id
      acquire_lock_for(work_id) do
        @target_permissions = nil # Clear cached ACL before reloading work
        @work = Hyrax.query_service.find_by(id: work_id) # reload work so we are sure to have the most recent version after locking
        work.member_ids += file_ids
        first_file_id = file_ids.first
        work.representative_id = first_file_id if work.respond_to?(:representative_id) && work.representative_id.blank?
        work.thumbnail_id = first_file_id if work.respond_to?(:thumbnail_id) && work.thumbnail_id.blank?
        @persister.save(resource: work)
        Hyrax.publisher.publish('object.metadata.updated', object: work, user: user)
      end
    end

    ##
    # @api private
    def update_file_set(file_set, file)
      # copy ACLs; should we also be propogating embargo/lease?
      Hyrax::AccessControlList.copy_permissions(source: target_permissions, target: file_set)
      # set visibility from params and save
      file_visibility = file_set_extra_params(file)[:visibility]
      file_set.visibility = file_visibility if file_visibility.present?
      permission_manager = file_set.permission_manager.acl
      permission_manager.save if permission_manager.pending_changes?
      @persister.save(resource: file_set)
    end

    ##
    # @api private
    def find_or_create_file_set(file, file_set_params)
      file_set_uri = file.file_set_uri
      if file_set_uri
        # we should probably update other things here as well?
        file_set = Hyrax.query_service.find_by(id: file_set_uri)
        @persister.save(resource: file_set)
      else
        file_set = @persister.save(resource: Hyrax::FileSet.new(file_set_args(file, file_set_params)))
        Hyrax.publisher.publish('object.deposited', object: file_set, user: file.user)
        file.add_file_set!(file_set)
      end
      file_set
    end

    ##
    # @api private
    #
    # @note the second hash overrides values in the first hash
    #
    #
    # @return [Hash{Symbol => Object}]
    def file_set_args(file, file_set_params = {})
      filename = file.uploader.filename
      user_key = file.user.user_key
      { depositor: user_key,
        creator: user_key,
        date_uploaded: file.created_at,
        date_modified: Hyrax::TimeService.time_in_utc,
        label: filename,
        title: filename }.merge(file_set_params)
    end

    ##
    # @api private
    #
    # return [Hash(Symbol => Object)]
    def file_set_extra_params(file)
      file_set_params&.find { |fs| fs[:uploaded_file_id] == file.id.to_s } || {}
    end

    ##
    # @api private
    #
    # @note cache these per instance to avoid repeated lookups.
    #
    # @return [Hyrax::AccessControlList] permissions to set on created filesets
    def target_permissions
      @target_permissions ||= Hyrax::AccessControlList.new(resource: work)
    end

    ##
    # @api private
    #
    # @note ported from AttachFilesToWorkJob. do we need this? maybe we should
    #   validate something other than type?
    #
    # @raise [ArgumentError] if any of the uploaded files aren't the right class
    def validate_files(files)
      files.each do |file|
        next if file.is_a? Hyrax::UploadedFile
        raise ArgumentError, "Hyrax::UploadedFile required, but #{file.class} received: #{file.inspect}"
      end
    end
  end
end
