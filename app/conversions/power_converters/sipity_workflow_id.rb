# frozen_string_literal: true
PowerConverter.define_conversion_for(:sipity_workflow_id) do |input|
  case input
  when Sipity::Workflow
    input.id
  when Integer
    input
  when String
    input.to_i
  else
    if input.respond_to?(:workflow_id)
      input.workflow_id
    else
      PowerConverter.convert_to_sipity_workflow_id(PowerConverter.convert_to_sipity_entity(input))
    end
  end
end
