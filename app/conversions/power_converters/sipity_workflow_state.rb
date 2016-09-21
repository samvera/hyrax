require 'power_converter'

PowerConverter.define_conversion_for(:sipity_workflow_state) do |input, workflow|
  case input
  when Sipity::WorkflowState
    input
  when Symbol, String
    Sipity::WorkflowState.where(workflow_id: workflow.id, name: input).first
  end
end
