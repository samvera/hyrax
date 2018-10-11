class IngestLocalFileJob < Hyrax::ApplicationJob
  queue_as Hyrax.config.ingest_queue_name

  # @param [FileSet] file_set
  # @param [String] path
  # @param [User] user
  def perform(file_set, path, user)
    file_set.label ||= File.basename(path)

    actor = Hyrax::Actors::FileSetActor.new(file_set, user)

    if actor.create_content(File.open(path))
      Hyrax.config.callback.run(:after_import_local_file_success, file_set, user, path)
    else
      Hyrax.config.callback.run(:after_import_local_file_failure, file_set, user, path)
    end
  rescue SystemCallError => error
    # This is generic in order to handle Errno constants raised when accessing files
    # @see https://ruby-doc.org/core-2.5.3/Errno.html
    send_error(error.message)
  end
end
