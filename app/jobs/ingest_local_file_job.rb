class IngestLocalFileJob < Hyrax::ApplicationJob
  queue_as Hyrax.config.ingest_queue_name

  # @param [FileSet] file_set
  # @param [String] path
  # @param [User] user
  def perform(file_set, path, user)
    file_set.label ||= File.basename(path)
    if create_content(file_set: file_set, file: File.open(path), user: user)
      Hyrax.config.callback.run(:after_import_local_file_success, file_set, user, path)
    else
      Hyrax.config.callback.run(:after_import_local_file_failure, file_set, user, path)
    end
  end

  private

    # @param file_set [FileSet]
    # @param file [File]
    # @param user [User]
    # @return [Boolean] true if successfully saved the file.
    def create_content(file_set:, file:, user:)
      update_file_set_title_and_label(file_set: file_set, path: file.path)

      wrapper = JobIoWrapper.create_with_varied_file_handling!(user: user,
                                                               file: file,
                                                               relation: Valkyrie::Vocab::PCDMUse.OriginalFile.to_s,
                                                               file_set: file_set)
      wrapper.ingest_file ? true : false
    end

    def update_file_set_title_and_label(file_set:, path:)
      return unless file_set.label.nil? || file_set.title.blank?
      file_set.label ||= File.basename(path)
      file_set.title = [file_set.label] if file_set.title.blank?

      # Save the updated title and label
      persister.save(resource: file_set)
    end

    def persister
      Valkyrie::MetadataAdapter.find(:indexing_persister).persister
    end
end
