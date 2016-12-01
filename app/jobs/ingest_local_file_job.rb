class IngestLocalFileJob < ActiveJob::Base
  queue_as Sufia.config.ingest_queue_name

  # @param [FileSet] file_set
  # @param [String] path
  # @param [User] user
  def perform(file_set, path, user)
    file_set.label ||= File.basename(path)

    actor = Sufia::Actors::FileSetActor.new(file_set, user)

    if actor.create_content(File.open(path))
      FileUtils.rm(path)
      Sufia.config.callback.run(:after_import_local_file_success, file_set, user, path)
    else
      Sufia.config.callback.run(:after_import_local_file_failure, file_set, user, path)
    end
  end
end
