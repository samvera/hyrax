require 'power_converter'
PowerConverter.define_conversion_for(:sipity_entity) do |input|
  case input
  when Sipity::Entity
    input
  when Sipity::Comment
    PowerConverter.convert_to_sipity_entity(input.entity)
  end
end
