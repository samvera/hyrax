# frozen_string_literal: true
PowerConverter.define_conversion_for(:sipity_agent) do |input|
  Deprecation.warn('PowerConverter is deprecated. Use `Sipity::Agent(input)` instead')

  case input
  when Sipity::Agent
    input
  end
end
