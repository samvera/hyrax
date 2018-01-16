# frozen_string_literals: true

module Hyrax
  # responsible for reverting to an old version of a File
  class RevertFileChangeSetPersister < ChangeSetPersister
    # TODO: this is not yet implemented because we have to implement versions
    #       before we can revert to a version.
    def save(change_set:)
      return false unless build_file_actor(change_set).revert_to(change_set.revision)
      Hyrax.config.callback.run(:after_revert_content, change_set.resource, change_set.user, change_set.revision)
      super
    end

    def build_file_actor(change_set)
      Hyrax::Actors::FileActor.new(change_set.resource, relation, change_set.user)
    end

    def relation
      Valkyrie::Vocab::PCDMUse.OriginalFile
    end
  end
end
