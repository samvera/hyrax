module Hyrax
  class EmbargoChangeSet < Valkyrie::ChangeSet
    property :parent_resource, virtual: true
    delegate :human_readable_type, :to_s, :model_name, to: :parent_resource

    property :embargo_release_date
    property :visibility_during_embargo
    property :visibility_after_embargo
    property :embargo_history

    def page_title
      [parent_resource.to_s, "#{human_readable_type} [#{parent_resource.to_param}]"]
    end
  end
end
