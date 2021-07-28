# frozen_string_literal: true
class IngestLocalFileJob < Hyrax::ApplicationJob
  queue_as Hyrax.config.ingest_queue_name

  # @param [FileSet, Hyrax::FileSet] file_set
  # @param [String] path
  # @param [User] user
  def perform(file_set, path, user)
    case file_set
    when ActiveFedora::Base
      __perform(file_set, path, user, use_valkyrie: false)
    else
      __perform(file_set, path, user, use_valkyrie: true)
    end
  end

  private

  # @note Based on the present implementation (see SHA a8597884e) of
  # the Hyrax::Actors::FileSetActor, we wouldn't need to pass the
  # `use_valkyrie` parameter.  However, I want to include this logic
  # to demonstrate that "Yes, the IngestLocalFileJob has been tested
  # for Valkyrie usage"
  def __perform(file_set, path, user, use_valkyrie:)
    file_set.label ||= File.basename(path)

    actor = Hyrax::Actors::FileSetActor.new(file_set, user, use_valkyrie: use_valkyrie)

    if actor.create_content(File.open(path))
      Hyrax.config.callback.run(:after_import_local_file_success, file_set, user, path, warn: false)
    else
      Hyrax.config.callback.run(:after_import_local_file_failure, file_set, user, path, warn: false)
    end
  rescue SystemCallError
    # This is generic in order to handle Errno constants raised when accessing files
    # @see https://ruby-doc.org/core-2.5.3/Errno.html
    Hyrax.config.callback.run(:after_import_local_file_failure, file_set, user, path, warn: false)
  end
end
