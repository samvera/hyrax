# frozen_string_literal: true

# rubocop:disable Style/RaiseArgs
module Sipity
  ##
  # Cast an object to a WorkflowAction in a given workflow
  def WorkflowAction(input, workflow) # rubocop:disable Naming/MethodName
    workflow_id = PowerConverter.convert_to_sipity_workflow_id(workflow)

    result = case input
             when WorkflowAction
               input if input.workflow_id == workflow_id
             when String, Symbol
               WorkflowAction.find_by(workflow_id: workflow_id, name: input.to_s)
             end

    result ||= input.try(:to_sipity_action)
    return result unless result.nil?
    return yield if block_given?

    raise ConversionError.new(input)
  end
  module_function :WorkflowAction

  # rubocop:enable Style/RaiseArgs
  class ConversionError < PowerConverter::ConversionError
    def initialize(value, **options)
      options[:scope] ||= nil
      options[:to]    ||= nil
      super(value, options)
    end
  end
end
