module Hyrax
  class RevertFileChangeSet < Valkyrie::ChangeSet
    property :revision, multiple: false, required: true, virtual: true
    property :search_context, virtual: true

    def user
      search_context.current_ability.current_user
    end
  end
end
