# frozen_string_literal: true
PowerConverter.define_conversion_for(:sipity_role) do |input|
  Deprecation.warn('PowerConverter is deprecated. Use `Sipity::WorkflowAction.name_for(input)` instead')
  case input
  when Sipity::Role
    input
  when String, Symbol
    Sipity::Role.find_or_create_by(name: input)
  end
end
