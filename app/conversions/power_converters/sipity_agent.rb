# frozen_string_literal: true

PowerConverter.define_conversion_for(:sipity_agent) do |input|
  case input
  when Sipity::Agent
    input
  end
end
