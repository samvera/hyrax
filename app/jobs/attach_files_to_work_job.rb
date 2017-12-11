# Converts UploadedFiles into FileSets and attaches them to works.
class AttachFilesToWorkJob < Hyrax::ApplicationJob
  queue_as Hyrax.config.ingest_queue_name

  # @param [Valkyrie::Resource] work - the work object
  # @param [Array<Hyrax::UploadedFile>] uploaded_files - an array of files to attach
  # rubocop:disable Metrics/MethodLength
  def perform(work, uploaded_files, **_work_attributes)
    validate_files!(uploaded_files)
    user = User.find_by_user_key(work.depositor) # BUG? file depositor ignored
    edit_users = work.edit_users
    read_users = work.read_users
    edit_groups = work.edit_groups
    read_groups = work.read_groups

    # metadata = visibility_attributes(work_attributes)
    uploaded_files.each do |uploaded_file|
      change_set = build_change_set(user: user,
                                    edit_users: edit_users,
                                    read_user: read_users,
                                    edit_groups: edit_groups,
                                    read_groups: read_groups)
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
    end
    metadata_adapter.persister.save(resource: work)
  end

  private

    # The attributes used for visibility - sent as initial params to created FileSets.
    def visibility_attributes(attributes)
      attributes.slice(:visibility, :visibility_during_lease,
                       :visibility_after_lease, :lease_expiration_date,
                       :embargo_release_date, :visibility_during_embargo,
                       :visibility_after_embargo)
    end

    def validate_files!(uploaded_files)
      uploaded_files.each do |uploaded_file|
        next if uploaded_file.is_a? Hyrax::UploadedFile
        raise ArgumentError, "Hyrax::UploadedFile required, but #{uploaded_file.class} received: #{uploaded_file.inspect}"
      end
    end

    def build_change_set(attributes)
      Hyrax::FileSetChangeSet.new(FileSet.new, attributes).tap(&:sync)
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
