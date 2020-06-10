# frozen_string_literal: true
class MultifileInput < SimpleForm::Inputs::CollectionInput
  def input(wrapper_options = nil)
    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)

    merged_input_options[:name] = "#{@builder.object_name}[#{attribute_name}][]"
    @builder.file_field(attribute_name, merged_input_options)
  end
end
