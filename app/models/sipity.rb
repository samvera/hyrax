# frozen_string_literal: true

##
# {Sipity} is a workflow/state engine.
#
# This module and the classes namespaced within it provide a domain model and
# implementation for managing the movement of repository objects through a
# defined workflow. The workflows themselves are configured using JSON documents
# and loaded into the database/domain model as {Sipity::Workflow}. Each workflow
# can be understood as finite sets of {Sipity::WorkflowState},
# {Sipity::WorkflowAction} (transitions from state to state), and {Sipity::Role}
# authorized to carry out each action.
#
# Any uniquely identifiable object can be managed by a {Sipity::Workflow}.
# Normally Hyrax uses workflows to handle the deposit process and maintenance
# lifecycle of repository objects at the level of the Work (within the Hydra
# Works model). Objects are represented within the Sipity engine's domain model
# by a {Sipity::Entity}. Each object has at most one {Sipity::Entity}, is
# governed by one {Sipity::Workflow}, and in one {Sipity::WorkflowState} at any
# given time.
#
# Some use cases for Sipity workflows include:
#
# * Simple unmediated deposit with on-deposit notifications and actions;
# * Mediated deposit with one or more review steps;
# * Publication workflows requiring multiple levels of editorial approval
#   and/or peer review;
# * Preservation processes involving post-deposit selection of objects for
#   replication to external preservation platforms and/or required action
#   in case of failed fixity checks;
# * Electronic Thesis & Dissertation submission processes involving (e.g.)
#   student deposit, committee and/or departmental approval, centralized/
#   graduate school review, and a final graduation step.
#
module Sipity
  ##
  # Cast a given input (e.g. a +::User+ or {Hyrax::Group} to a {Sipity::Agent}).
  #
  # @param input [Object]
  #
  # @return [Sipity::Agent]
  def Agent(input, &block) # rubocop:disable Naming/MethodName
    result = case input
             when Sipity::Agent
               input
             end

    handle_conversion(input, result, :to_sipity_agent, &block)
  end
  module_function :Agent

  ##
  # Cast an object to an Entity
  #
  # @param input [Object]
  #
  # @return [Sipity::Entity]
  # rubocop:disable Naming/MethodName, Metrics/CyclomaticComplexity, Metrics/MethodLength
  def Entity(input, &block) # rubocop:disable Metrics/AbcSize
    Hyrax.logger.debug("Trying to make an Entity for #{input.inspect}")

    result = case input
             when Sipity::Entity
               input
             when URI::GID, GlobalID
               Hyrax.logger.debug("Entity() got a GID, searching by proxy")
               Entity.find_by(proxy_for_global_id: input.to_s)
             when SolrDocument
               Hyrax.logger.debug("Entity() got a SolrDocument, retrying on #{input.to_model}")
               Entity(input.to_model)
             when Draper::Decorator
               Hyrax.logger.debug("Entity() got a Decorator, retrying on #{input.model}")
               Entity(input.model)
             when Sipity::Comment
               Hyrax.logger.debug("Entity() got a Comment, retrying on #{input.entity}")
               Entity(input.entity)
             when Valkyrie::Resource
               Hyrax.logger.debug("Entity() got a Resource, retrying on #{Hyrax::GlobalID(input)}")
               Entity(Hyrax::GlobalID(input))
             else
               Hyrax.logger.debug("Entity() got something else, testing #to_global_id")
               Entity(input.to_global_id) if input.respond_to?(:to_global_id)
             end

    Hyrax.logger.debug("Entity(): attempting conversion on #{result}")
    handle_conversion(input, result, :to_sipity_entity, &block)
  rescue URI::GID::MissingModelIdError
    Entity(nil)
  end # rubocop:enable Metrics/AbcSize
  module_function :Entity
  # rubocop:enable Naming/MethodName, Metrics/CyclomaticComplexity, Metrics/MethodLength

  ##
  # Cast an object to an Role
  def Role(input, &block) # rubocop:disable Naming/MethodName
    result = case input
             when Sipity::Role
               input
             when String, Symbol
               Sipity::Role.find_or_create_by(name: input)
             end

    handle_conversion(input, result, :to_sipity_role, &block)
  end
  module_function :Role

  ##
  # Cast an object to a Workflow id
  # rubocop:disable Metrics/MethodLength
  def WorkflowId(input, &block) # rubocop:disable Naming/MethodName
    result = case input
             when Sipity::Workflow
               input.id
             when Integer
               input
             when String
               input.to_i
             else
               if input.respond_to?(workflow_id)
                 input.workflow_id
               else
                 WorkflowId(Entity(input))
               end
             end
    handle_conversion(input, result, :to_workflow_id, &block)
  end
  module_function :WorkflowId
  # rubocop:enable Metrics/MethodLength

  ##
  # Cast an object to a WorkflowAction in a given workflow
  def WorkflowAction(input, workflow, &block) # rubocop:disable Naming/MethodName
    workflow_id = WorkflowId(workflow)

    result = case input
             when WorkflowAction
               input if input.workflow_id == workflow_id
             when String, Symbol
               WorkflowAction.find_by(workflow_id: workflow_id, name: input.to_s)
             end

    handle_conversion(input, result, :to_sipity_action, &block)
  end
  module_function :WorkflowAction

  ##
  # Cast an object to a WorkflowState in a given workflow
  def WorkflowState(input, workflow, &block) # rubocop:disable Naming/MethodName
    result = case input
             when Sipity::WorkflowState
               input
             when Symbol, String
               WorkflowState.find_by(workflow_id: workflow.id, name: input)
             end

    handle_conversion(input, result, :to_sipity_workflow_state, &block)
  end
  module_function :WorkflowState

  ##
  # A parent error class for all workflow errors caused by bad state
  class StateError < RuntimeError; end

  class ConversionError < RuntimeError
    def initialize(value)
      super("Unable to convert #{value.inspect}")
    end
  end

  ##
  # Provides compatibility with the old `PowerConverter` conventions
  def handle_conversion(input, result, method_name)
    result ||= input.try(method_name)
    return result unless result.nil?
    return yield if block_given?

    raise ConversionError.new(input) # rubocop:disable Style/RaiseArgs
  end
  module_function :handle_conversion
end
