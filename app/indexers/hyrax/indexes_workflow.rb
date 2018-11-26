module Hyrax
  module IndexesWorkflow
    STORED_BOOL = ActiveFedora::Indexing::Descriptor.new(:boolean, :stored, :indexed)

    mattr_accessor :suppressed_field, instance_writer: false do
      ActiveFedora.index_field_mapper.solr_name('suppressed', STORED_BOOL)
    end

    # Adds thumbnail indexing to the solr document
    def generate_solr_document
      super.tap do |solr_doc|
        index_suppressed(solr_doc)
        index_workflow_fields(solr_doc)
      end
    end

    # Write the suppressed status into the solr_document
    # @param [Hash] solr_document the solr document to add the field to
    def index_suppressed(solr_document)
      solr_document[suppressed_field] = object.suppressed?
    end

    # Write the workflow roles and state so one can see where the document moves to next
    # @param [Hash] solr_document the solr document to add the field to
    def index_workflow_fields(solr_document)
      return unless object.persisted?
      entity = PowerConverter.convert_to_sipity_entity(object)
      return if entity.nil?
      solr_document[workflow_role_field] = workflow_roles(entity).map { |role| "#{entity.workflow.permission_template.source_id}-#{entity.workflow.name}-#{role}" }
      solr_document[workflow_state_name_field] = entity.workflow_state.name if entity.workflow_state
    end

    def workflow_state_name_field
      @workflow_state_name_field ||= ActiveFedora.index_field_mapper.solr_name('workflow_state_name', :symbol)
    end

    def workflow_role_field
      @workflow_role_field ||= ActiveFedora.index_field_mapper.solr_name('actionable_workflow_roles', :symbol)
    end

    def workflow_roles(entity)
      Hyrax::Workflow::PermissionQuery.scope_roles_associated_with_the_given_entity(entity: entity)
    end
  end
end
