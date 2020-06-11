# frozen_string_literal: true
module Sipity
  # In what capacity can an agent act upon the given entity?
  #
  # This is an analogue to the Sipity::WorkflowResponsibility, but
  # the responsibility only applies to the given entity.
  #
  # @example
  #   An Advisor for a given Student would have an
  #   EntitySpecificResponsibility to review an ETD submitted by the
  #   given Student.
  #   The Graduate School Reviewer would have a WorkflowResponsibility
  #   to review all ETDs submitted.
  #
  # @see Sipity::WorkflowResponsibility
  class EntitySpecificResponsibility < ActiveRecord::Base
    self.table_name = 'sipity_entity_specific_responsibilities'
    belongs_to :entity, class_name: 'Sipity::Entity'
    belongs_to :workflow_role, class_name: 'Sipity::WorkflowRole'
    belongs_to :agent, class_name: 'Sipity::Agent'
  end
end
