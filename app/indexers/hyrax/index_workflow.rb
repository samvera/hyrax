module Hyrax
  # Adds workflow indexing to the solr document
  class IndexWorkflow
    STORED_BOOL = Solrizer::Descriptor.new(:boolean, :stored, :indexed)

    mattr_accessor :suppressed_field, instance_writer: false do
      Solrizer.solr_name('suppressed', STORED_BOOL)
    end

    def initialize(resource:)
      @resource = resource
    end

    # @return [Hash] a partial solr document with object suppression and workflows
    def to_solr
      # Filter out AdminSets and Collections
      return {} unless resource.respond_to?(:suppressed?)
      {}.tap do |solr_doc|
        index_suppressed(solr_doc)
        index_workflow_fields(solr_doc)
      end
    end

    private

      attr_reader :resource

      # Write the suppressed status into the solr_document
      # @param [Hash] solr_document the solr document to add the field to
      def index_suppressed(solr_document)
        solr_document[suppressed_field] = resource.suppressed?
      end

      # Write the workflow roles and state so one can see where the document moves to next
      # @param [Hash] solr_document the solr document to add the field to
      def index_workflow_fields(solr_document)
        return unless resource.persisted?
        entity = resource.to_sipity_entity
        return if entity.nil?
        solr_document[workflow_role_field] = workflow_roles(entity).map { |role| "#{entity.workflow.permission_template.admin_set_id}-#{entity.workflow.name}-#{role}" }
        solr_document[workflow_state_name_field] = entity.workflow_state.name if entity.workflow_state
      end

      def workflow_state_name_field
        @workflow_state_name_field ||= Solrizer.solr_name('workflow_state_name', :symbol)
      end

      def workflow_role_field
        @workflow_role_field ||= Solrizer.solr_name('actionable_workflow_roles', :symbol)
      end

      def workflow_roles(entity)
        Hyrax::Workflow::PermissionQuery.scope_roles_associated_with_the_given_entity(entity: entity)
      end
  end
end
