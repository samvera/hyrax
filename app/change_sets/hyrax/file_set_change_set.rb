module Hyrax
  class FileSetChangeSet < Valkyrie::ChangeSet
    property :read_users, multiple: true, required: false
    property :read_groups, multiple: true, required: false
    property :edit_users, multiple: true, required: false
    property :edit_groups, multiple: true, required: false
  end
end
