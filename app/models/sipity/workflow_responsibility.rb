# frozen_string_literal: true
module Sipity
  # In what capacity can an agent act upon all entities for the given
  # Workflow
  #
  # This is an analogue to the Sipity::EntitySpecificResponsibility, but
  # the responsibility only applies to all entities for the given
  # Workflow
  #
  # @example
  #   An Advisor for a given Student would have an
  #   EntitySpecificResponsibility to review an ETD submitted by the
  #   given Student.
  #   The Graduate School Reviewer would have a WorkflowResponsibility
  #   to review all ETDs submitted.
  #
  # @see Sipity::Role for discussion of roles
  # @see Sipity::EntitySpecificResponsibility
  class WorkflowResponsibility < ActiveRecord::Base
    self.table_name = 'sipity_workflow_responsibilities'
    belongs_to :agent, class_name: 'Sipity::Agent'
    belongs_to :workflow_role, class_name: 'Sipity::WorkflowRole'
  end
end
