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
  # set to that value. When all of the `files` have been processed, the work is
  # reloaded under a lock via `Lockable` (Redis/Redlock), the new members are
  # appended to it and it is saved, so members another handler added since `work`
  # was read are kept. A `ValkyrieIngestJob` is then enqueued for each `FileSet`.
  #
  # An upload whose `FileSet` was created by an earlier attempt, but not
  # attached to any work, attaches that `FileSet` instead of creating another.
  # An upload whose `FileSet` is gone or already in a work is skipped. Attaching
  # the same upload to two works at once is not supported: if one handler
  # creates the `FileSet` while another reuses it, both works may take it.
  #
  # The work is reloaded before it is saved, so after `#attach` read `#work`
  # for the saved work rather than the object passed in.
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
      @work = work
      @persister = persister
    end

    ##
    # @api public
    #
    # @note we discard uploads whose file set is already a member of the work,
    #   so a retried job does not attach it again.
    #
    # @param [Enumerable<Hyrax::UploadedFile>] files  files to add
    #
    # @param [Enumerable<Hash>] file_set_params additional parameters for each file_set
    #
    # @return [WorkFileSetManager] self
    # @raise [ArgumentError] if any of the uploaded files are not an
    #   `UploadedFile`
    def add(files:, file_set_params: [])
      validate_files(files) &&
        @files = Array.wrap(files).reject { |f| work.member_ids.include?(f.file_set_uri) }
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

      # Holding a lock on each reused file set until the work is saved keeps two
      # works from both finding it unattached; sorted keys avoid deadlock.
      event_payloads, added_ids = acquire_locks_for(files.filter_map(&:file_set_uri).uniq.sort) { attach_file_sets }
      event_payloads.select { |payload| added_ids.include?(payload[:file_set].id) }.each do |payload|
        payload.delete(:job).enqueue
        Hyrax.publisher.publish('file.set.attached', payload)
      end
    end

    private

    ##
    # @api private
    def acquire_locks_for(keys, &block)
      return yield if keys.empty?

      acquire_lock_for(keys.first) { acquire_locks_for(keys.drop(1), &block) }
    end

    ##
    # @api private
    #
    # @return [Array(Array<Hash>, Array<Valkyrie::ID>)] the event payloads and
    #   the ids of the file sets added to the work
    def attach_file_sets
      event_payloads = files.each_with_object([]).with_index do |(file, arry), index|
        payload = make_file_set_and_ingest(file, @file_set_params[index] || {})
        arry << payload if payload
      end
      [event_payloads, append_to_work(event_payloads.map { |payload| payload[:file_set] }, user: files.first.user)]
    end

    ##
    # @api private
    def make_file_set_and_ingest(file, file_set_params = {})
      file_set = find_or_create_file_set(file, file_set_params)
      return unless file_set

      # copy ACLs; should we also be propogating embargo/lease?
      Hyrax::AccessControlList.copy_permissions(source: target_permissions, target: file_set)

      # set visibility from params and save
      file_set.visibility = file_set_extra_params(file)[:visibility] if file_set_extra_params(file)[:visibility].present?
      file_set.permission_manager.acl.save if file_set.permission_manager.acl.pending_changes?

      { file_set: file_set, user: file.user, job: ValkyrieIngestJob.new(file) }
    end

    ##
    # @api private
    #
    # @return [Hyrax::FileSet, nil] nil when the upload's file set is gone or
    #   already in a work, which this upload must not take over
    def find_or_create_file_set(file, file_set_params)
      return unattached_file_set(file.file_set_uri) if file.file_set_uri.present?

      file_set = @persister.save(resource: Hyrax.config.valkyrie_file_set_class.new(file_set_args(file, file_set_params)))
      Hyrax.publisher.publish('object.deposited', object: file_set, user: file.user)
      file.add_file_set!(file_set)
      file_set
    end

    ##
    # @api private
    def unattached_file_set(id)
      return if active_fedora_uri?(id)

      file_set = Hyrax.query_service.find_by(id: id)
      file_set unless Hyrax.custom_queries.find_parent_work(resource: file_set)
    rescue Valkyrie::Persistence::ObjectNotFoundError
      nil
    end

    ##
    # @api private
    #
    # `UploadedFile#add_file_set!` stores an ActiveFedora file set's URI rather
    # than its id, which Valkyrie cannot look up.
    def active_fedora_uri?(file_set_uri)
      file_set_uri.include?('://')
    end

    ##
    # @api private
    #
    # @todo figure out how to know less about Work's ideas about FileSet use here. Maybe post-Wings, work.
    #
    # @return [Array<Valkyrie::ID>] the ids of the file sets added; those
    #   already members of the reloaded work are skipped
    def append_to_work(file_sets, user:)
      acquire_lock_for(work.id) do
        @work = Hyrax.query_service.find_by(id: work.id)
        added_ids = file_sets.map(&:id) - work.member_ids
        next added_ids if added_ids.empty?

        work.member_ids += added_ids
        default_representative_and_thumbnail_to(added_ids.first)
        @work = @persister.save(resource: work)
        Hyrax.publisher.publish('object.metadata.updated', object: work, user: user)
        added_ids
      end
    end

    ##
    # @api private
    def default_representative_and_thumbnail_to(file_set_id)
      work.representative_id = file_set_id if work.respond_to?(:representative_id) && work.representative_id.blank?
      work.thumbnail_id = file_set_id if work.respond_to?(:thumbnail_id) && work.thumbnail_id.blank?
    end

    ##
    # @api private
    #
    # @note the second hash overrides values in the first hash
    #
    #
    # @return [Hash{Symbol => Object}]
    def file_set_args(file, file_set_params = {})
      extra = file_set_params.respond_to?(:to_unsafe_h) ? file_set_params.to_unsafe_h : file_set_params.to_h
      { depositor: file.user.user_key,
        creator: Array.wrap(file.user.user_key),
        date_uploaded: file.created_at,
        date_modified: Hyrax::TimeService.time_in_utc,
        label: file.uploader.filename,
        title: Array.wrap(file.uploader.filename) }.merge(extra.symbolize_keys)
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
