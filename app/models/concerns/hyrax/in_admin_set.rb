module Hyrax
  module InAdminSet
    extend ActiveSupport::Concern

    included do
      attribute :admin_set_id, Valkyrie::Types::ID.optional
    end

    def active_workflow
      Sipity::Workflow.find_active_workflow_for(admin_set_id: admin_set_id.to_s)
    end
  end
end
