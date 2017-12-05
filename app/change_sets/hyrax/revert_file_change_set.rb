module Hyrax
  class RevertFileChangeSet < Valkyrie::ChangeSet
    property :revision, multiple: false, required: true, virtual: true
    property :search_context, virtual: true

    delegate :user, to: :search_context
  end
end
