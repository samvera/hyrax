# frozen_string_literal: true
PowerConverter.define_conversion_for(:sipity_action_name) do |input|
  Deprecation.warn('PowerConverter is deprecated. Use `Sipity::WorkflowAction.name_for(input)` instead')
  case input
  when String, Symbol
    input.to_s.sub(/[\?\!]\Z/, '')
  when Sipity::WorkflowAction
    input.name
  end
end
