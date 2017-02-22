module Hyrax
  module InAdminSet
    extend ActiveSupport::Concern

    included do
      belongs_to :admin_set, predicate: ::RDF::Vocab::DC.isPartOf
    end

    def active_workflow
      Sipity::Workflow.find_active_workflow_for(admin_set_id: admin_set_id)
    end
  end
end
