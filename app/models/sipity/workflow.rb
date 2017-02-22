module Sipity
  # A named workflow for processing an entity. Originally I had thought of
  # calling this a Type, but once I extracted the Processing submodule,
  # type felt to much of a noun, not conveying potentiality. Workflow
  # conveys "things will happen" because of this.
  class Workflow < ActiveRecord::Base
    self.table_name = 'sipity_workflows'

    has_many :entities, dependent: :destroy, class_name: 'Sipity::Entity'
    has_many :workflow_states, dependent: :destroy, class_name: 'Sipity::WorkflowState'
    has_many :workflow_actions, dependent: :destroy, class_name: 'Sipity::WorkflowAction'
    has_many :workflow_roles, dependent: :destroy, class_name: 'Sipity::WorkflowRole'

    # Each PermissionTemplate has multiple potential workflows. But only one "active" workflow
    # @see Sipity::Workflow.activate!
    belongs_to :permission_template, class_name: 'Hyrax::PermissionTemplate', required: true

    DEFAULT_INITIAL_WORKFLOW_STATE = 'new'.freeze
    def initial_workflow_state
      workflow_states.find_or_create_by!(name: DEFAULT_INITIAL_WORKFLOW_STATE)
    end

    # @api public
    # @param admin_set_id [#to_s] the admin set to which we will scope our query.
    # @return [Sipity::Workflow] that is active for the given administrative set`
    # @raise [ActiveRecord::RecordNotFound] when we don't have an active admin set for the given administrative set's ID
    def self.find_active_workflow_for(admin_set_id:)
      templates = Hyrax::PermissionTemplate.arel_table
      workflows = Sipity::Workflow.arel_table
      Sipity::Workflow.where(active: true).where(
        workflows[:permission_template_id].in(
          templates.project(templates[:id]).where(templates[:admin_set_id].eq(admin_set_id))
        )
      ).first!
    end

    # @api public
    #
    # Within the given permission_template scope:
    #   * Deactivate the current active workflow (if one exists)
    #   * Activate the specified workflow_id
    #
    # @param permission_template [Hyrax::PermissionTemplate] The scope for activation of the workflow id
    # @param workflow_id [Integer] The workflow_id within the given permission_template that should be activated
    # @return [TrueClass]
    # @raise [ActiveRecord::RecordNotFound] When we have a mismatch on permission template and workflow id
    def self.activate!(permission_template:, workflow_id:)
      Sipity::Workflow.find_by!(permission_template: permission_template, id: workflow_id).tap do |workflow|
        Sipity::Workflow.where(permission_template: permission_template, active: true).update(active: nil)
        workflow.update!(active: true)
      end
    end
  end
end
