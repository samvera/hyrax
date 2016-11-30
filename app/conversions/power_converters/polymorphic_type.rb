PowerConverter.define_conversion_for(:polymorphic_type) do |input|
  if input.respond_to?(:base_class)
    input.base_class
  elsif input.is_a?(ActiveRecord::Base)
    input.class.base_class
  end
end
