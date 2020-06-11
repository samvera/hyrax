# frozen_string_literal: true
module Hyrax
  class FormBuilder < SimpleForm::FormBuilder
    def input_label(attribute_name, options = {})
      options = options.dup
      options[:input_html] = options.except(:as, :boolean_style, :collection, :label_method, :value_method, *ATTRIBUTE_COMPONENTS)
      options = @defaults.deep_dup.deep_merge(options) if @defaults

      input      = find_input(attribute_name, options)
      wrapper    = find_wrapper(input.input_type, options)
      components = (wrapper.components.map(&:namespace) & ATTRIBUTE_COMPONENTS) + [:input]
      components.map { |component| SimpleForm::Wrappers::Leaf.new(component) }

      input.label.html_safe
    end
  end
end
