# frozen_string_literals: true

module Hyrax
  # responsible for reverting to an old version of a File
  class RevertFileChangeSetPersister < ChangeSetPersister
    # TODO: this is not yet implemented because we have to implement versions
    #       before we can revert to a version.
    # def save
    #   return false unless build_file_actor(relation).revert_to(revision_id)
    #   Hyrax.config.callback.run(:after_revert_content, file_set, user, revision_id)
    # end
  end
end
