PowerConverter.define_conversion_for(:sipity_action) do |input, scope|
  workflow_id = PowerConverter.convert_to_sipity_workflow_id(scope)
  case input
  when Sipity::WorkflowAction
    input if input.workflow_id == workflow_id
  when String, Symbol
    Sipity::WorkflowAction.find_by(workflow_id: workflow_id, name: input.to_s)
  end
end
