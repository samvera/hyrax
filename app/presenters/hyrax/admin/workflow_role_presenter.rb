# frozen_string_literal: true
module Hyrax
  module Admin
    # Displays a single workflow role
    class WorkflowRolePresenter
      def initialize(workflow_role)
        @workflow = workflow_role.workflow
        @role = workflow_role.role
        @source_id = workflow.permission_template.source_id
      end

      # @todo This is a hack; I don't want to include reference to the admin set;
      #       However based on the current UI, in which we list all workflows (spanning all admin sets) this is required.
      # @return [String] A meaningful label for the given WorkflowRole
      def label
        "#{admin_set_label(source_id)} - #{role.name} (#{workflow.name})"
      end

      private

      attr_accessor :workflow, :role, :source_id

      def admin_set_label(id)
        result = Hyrax::SolrService.search_by_id(id, fl: 'title_tesim')
        result['title_tesim'].first
      rescue ActiveFedora::ObjectNotFoundError
        "[AdminSet ID=#{id}]"
      end
    end
  end
end
