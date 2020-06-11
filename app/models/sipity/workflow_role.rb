# frozen_string_literal: true
module Sipity
  # For a given processing workflow, what roles have a part to play in
  # the processing?
  class WorkflowRole < ActiveRecord::Base
    self.table_name = 'sipity_workflow_roles'

    belongs_to :role, class_name: 'Sipity::Role'
    belongs_to :workflow, class_name: 'Sipity::Workflow'
    has_many :workflow_responsibilities, dependent: :destroy, class_name: 'Sipity::WorkflowResponsibility'
    has_many :workflow_state_action_permissions, dependent: :destroy, class_name: 'Sipity::WorkflowStateActionPermission'
    has_many :entity_specific_responsibilities, dependent: :destroy, class_name: 'Sipity::EntitySpecificResponsibility'
  end
end
