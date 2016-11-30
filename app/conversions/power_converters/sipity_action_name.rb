PowerConverter.define_conversion_for(:sipity_action_name) do |input|
  case input
  when String, Symbol
    input.to_s.sub(/[\?\!]\Z/, '')
  when Sipity::WorkflowAction
    input.name
  end
end
