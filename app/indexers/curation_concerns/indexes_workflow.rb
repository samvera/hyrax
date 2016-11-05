module CurationConcerns
  module IndexesWorkflow
    STORED_BOOL = Solrizer::Descriptor.new(:boolean, :stored, :indexed)
    # Adds thumbnail indexing to the solr document
    def generate_solr_document
      super.tap do |solr_doc|
        index_suppressed(solr_doc)
        index_workflow_fields(solr_doc)
      end
    end

    # Write the suppressed status into the solr_document
    # @params [Hash] solr_document the solr document to add the field to
    def index_suppressed(solr_document)
      solr_document[suppressed_field] = object.suppressed?
    end

    # Write the workflow roles and state so one can see where the document moves to next
    # @params [Hash] solr_document the solr document to add the field to
    def index_workflow_fields(solr_document)
      return unless object.persisted?
      entity = PowerConverter.convert_to_sipity_entity(object)
      return if entity.nil?
      solr_document[workflow_role_field] = workflow_roles(entity).map { |role| "#{entity.workflow.name}-#{role}" }
      solr_document[workflow_state_name_field] = entity.workflow_state.name if entity.workflow_state
    end

    def workflow_state_name_field
      @workflow_state_name_field ||= Solrizer.solr_name('workflow_state_name', :symbol)
    end

    def workflow_role_field
      @workflow_role_field ||= Solrizer.solr_name('actionable_workflow_roles', :symbol)
    end

    def workflow_roles(entity)
      CurationConcerns::Workflow::PermissionQuery.scope_roles_associated_with_the_given_entity(entity: entity)
    end

    def suppressed_field
      @suppressed_field ||= Solrizer.solr_name('suppressed', STORED_BOOL)
    end
  end
end
