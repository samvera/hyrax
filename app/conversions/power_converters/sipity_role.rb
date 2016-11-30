PowerConverter.define_conversion_for(:sipity_role) do |input|
  case input
  when Sipity::Role
    input
  when String, Symbol
    Sipity::Role.find_or_create_by(name: input)
  end
end
