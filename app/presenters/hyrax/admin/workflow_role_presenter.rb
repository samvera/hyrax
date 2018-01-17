module Hyrax
  module Admin
    # Displays a single workflow role
    class WorkflowRolePresenter
      def initialize(workflow_role)
        @workflow = workflow_role.workflow
        @role = workflow_role.role
        @admin_set_id = workflow.permission_template.admin_set_id
      end

      # @todo This is a hack; I don't want to include reference to the admin set;
      #       However based on the current UI, in which we list all workflows (spanning all admin sets) this is required.
      # @return [String] A meaningful label for the given WorkflowRole
      def label
        "#{admin_set_label(admin_set_id)} - #{role.name} (#{workflow.name})"
      end

      private

        attr_accessor :workflow, :role, :admin_set_id

        def admin_set_label(id)
          ::SolrDocument.find(id).title
        rescue Blacklight::Exceptions::RecordNotFound
          "[AdminSet ID=#{id}]"
        end
    end
  end
end
