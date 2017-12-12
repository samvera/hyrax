module Hyrax
  class LeaseChangeSet < Valkyrie::ChangeSet
    property :parent_resource, virtual: true
    delegate :human_readable_type, :to_s, :model_name, to: :parent_resource

    property :lease_expiration_date
    property :visibility_during_lease
    property :visibility_after_lease
    property :lease_history

    def page_title
      [parent_resource.to_s, "#{human_readable_type} [#{parent_resource.to_param}]"]
    end
  end
end
