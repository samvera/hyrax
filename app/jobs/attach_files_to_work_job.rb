# Converts UploadedFiles into FileSets and attaches them to works.
class AttachFilesToWorkJob < Hyrax::ApplicationJob
  queue_as Hyrax.config.ingest_queue_name

  # @param [Valkyrie::Resource] work - the work object
  # @param [Array<Hyrax::UploadedFile>] uploaded_files - an array of files to attach
  # rubocop:disable Metrics/MethodLength
  def perform(work, uploaded_files, **work_attributes)
    validate_files!(uploaded_files)

    metadata = visibility_attributes(work, work_attributes)
    uploaded_files.each do |uploaded_file|
      change_set = build_change_set(work, metadata)

      file_set = nil
      change_set_persister.buffer_into_index do |buffered_changeset_persister|
        file_set = buffered_changeset_persister.save(change_set: change_set)
      end
      # TODO: do we need to do the FileUploadChangeSet?
      # actor = Hyrax::Actors::FileSetActor.new(file_set, user)
      # actor.create_metadata(metadata)
      # actor.create_content(uploaded_file)
      # actor.attach_to_work(work)
      work.member_ids += [file_set.id]
      uploaded_file.update(file_set_uri: file_set.to_global_id)
      io = JobIoWrapper.create_with_varied_file_handling!(user: uploaded_file.user, file: uploaded_file, file_set: file_set, relation: Valkyrie::Vocab::PCDMUse.OriginalFile)
      io.file_actor.ingest_file(io)
    end
    metadata_adapter.persister.save(resource: work)
  end

  private

    # The attributes used for visibility - sent as initial params to created FileSets.
    def visibility_attributes(work, attributes)
      attributes.merge(
        user: User.find_by_user_key(work.depositor), # BUG? file depositor ignored
        edit_users: work.edit_users,
        read_users: work.read_users,
        edit_groups: work.edit_groups,
        read_groups: work.read_groups
      )
    end

    def validate_files!(uploaded_files)
      uploaded_files.each do |uploaded_file|
        next if uploaded_file.is_a? Hyrax::UploadedFile
        raise ArgumentError, "Hyrax::UploadedFile required, but #{uploaded_file.class} received: #{uploaded_file.inspect}"
      end
    end

    def build_change_set(work, attributes)
      change_set = Hyrax::FileSetChangeSet.new(FileSet.new, attributes).tap(&:sync)
      if work.embargo_id
        # create a copy of the embargo for the FileSet
        Hyrax::EmbargoService.apply_embargo(resource: change_set.resource,
                                            embargo_params: [attributes[:embargo_release_date],
                                                             attributes[:visibility_during_embargo],
                                                             attributes[:visibility_after_embargo]])
      end

      if work.lease_id
        Hyrax::LeaseService.apply_lease(resource: change_set.resource,
                                        lease_params: [attributes[:lease_expiration_date],
                                                       attributes[:visibility_during_lease],
                                                       attributes[:visibility_after_lease]])
      end
      change_set
    end

    def change_set_persister
      Hyrax::FileSetChangeSetPersister.new(
        metadata_adapter: metadata_adapter,
        storage_adapter: Valkyrie.config.storage_adapter
      )
    end

    def metadata_adapter
      Valkyrie::MetadataAdapter.find(:indexing_persister)
    end
end
