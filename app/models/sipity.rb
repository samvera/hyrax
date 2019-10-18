# frozen_string_literal: true

module Sipity
  ##
  # Cast an object to an Entity
  # rubocop:disable Naming/MethodName, Metrics/CyclomaticComplexity, Metrics/MethodLength
  def Entity(input, &block)
    result = case input
             when Sipity::Entity
               input
             when URI::GID, GlobalID
               Entity.find_by(proxy_for_global_id: input.to_s)
             when SolrDocument
               Entity(input.to_model)
             when Sipity::Comment
               Entity(input.entity)
             else
               Entity(input.to_global_id) if input.respond_to?(:to_global_id)
             end

    handle_conversion(input, result, :to_sipity_entity, &block)
  rescue URI::GID::MissingModelIdError
    Entity(nil)
  end
  module_function :Entity
  # rubocop:enable Naming/MethodName, Metrics/CyclomaticComplexity, Metrics/MethodLength

  ##
  # Cast an object to a WorkflowAction in a given workflow
  def WorkflowAction(input, workflow, &block) # rubocop:disable Naming/MethodName
    workflow_id = PowerConverter.convert_to_sipity_workflow_id(workflow)

    result = case input
             when WorkflowAction
               input if input.workflow_id == workflow_id
             when String, Symbol
               WorkflowAction.find_by(workflow_id: workflow_id, name: input.to_s)
             end

    handle_conversion(input, result, :to_sipity_action, &block)
  end
  module_function :WorkflowAction

  class ConversionError < PowerConverter::ConversionError
    def initialize(value, **options)
      options[:scope] ||= nil
      options[:to]    ||= nil
      super(value, options)
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
