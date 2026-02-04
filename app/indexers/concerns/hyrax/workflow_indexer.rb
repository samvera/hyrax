# frozen_string_literal: true

module Hyrax
  module WorkflowIndexer
    def to_solr
      super.tap do |solr_doc|
        index_suppressed(solr_doc)
        index_workflow_fields(solr_doc)
      end
    end

    def index_suppressed(solr_document)
      return unless resource.respond_to?(:suppressed?)
      solr_document['suppressed_bsi'] = resource.suppressed?
    end

    def index_workflow_fields(solr_document)
      entity = Sipity::Entity(resource)
      solr_document['actionable_workflow_roles_ssim'] = workflow_roles(entity).map { |role| "#{entity.workflow.permission_template.source_id}-#{entity.workflow.name}-#{role}" }
      solr_document['workflow_state_name_ssim'] = entity.workflow_state.name if entity.workflow_state
    rescue Sipity::ConversionError
      nil
    end

    def workflow_roles(entity)
      Hyrax::Workflow::PermissionQuery.scope_roles_associated_with_the_given_entity(entity: entity)
    end
  end
end
