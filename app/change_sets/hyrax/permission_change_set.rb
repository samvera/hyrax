module Hyrax
  class PermissionChangeSet < Valkyrie::ChangeSet
    property :agent_name
    property :access
    property :type

    def persisted?
      false
    end
  end
end
