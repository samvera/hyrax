module Hyrax
  class RevertFileChangeSet < Valkyrie::ChangeSet
    property :revision, multiple: false, required: true, virtual: true
    property :user, virtual: true
  end
end
