# frozen_string_literal: true

module Hyrax
  module WorkflowIndexer
    # Write the suppressed status and workflow roles and state into the solr_document
    # @param [Hash] solr_document the solr document to add the fields to
    def to_solr
      super.tap do |solr_doc|
        index_suppressed(solr_doc)
        index_workflow_fields(solr_doc)
      end
    end

    # Write the suppressed status into the solr_document
    # @param [Hash] solr_document the solr document to add the field to
    def index_suppressed(solr_document)
      return unless resource.respond_to?(:suppressed?)
      solr_document['suppressed_bsi'] = resource.suppressed?
    end

    # Write the workflow roles and state so one can see where the document moves to next
    # @param [Hash] solr_document the solr document to add the field to
    def index_workflow_fields(solr_document)
      entity = Sipity::Entity(resource)
      solr_document['actionable_workflow_roles_ssim'] = workflow_roles(entity).map { |role| "#{entity.workflow.permission_template.source_id}-#{entity.workflow.name}-#{role}" }
      solr_document['workflow_state_name_ssim'] = entity.workflow_state.name if entity.workflow_state
    rescue Sipity::ConversionError
      nil
    end

    # Get the workflow roles for the entity
    # @param [Sipity::Entity] entity the entity to get the workflow roles for
    # @return [Array<String>] the workflow roles for the entity
    def workflow_roles(entity)
      Hyrax::Workflow::PermissionQuery.scope_roles_associated_with_the_given_entity(entity: entity)
    end
  end
end
