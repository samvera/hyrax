class MultiValueSelectInput < MultiValueInput
  def input_type
    'multi_value'.freeze
  end

  private

    def select_options
      @select_options ||= begin
        collection = options.delete(:collection) || self.class.boolean_collection
        collection.respond_to?(:call) ? collection.call : collection.to_a
      end
    end

    def build_field_options(value)
      field_options = input_html_options.dup

      field_options[:value] = value
      if @rendered_first_element
        field_options[:id] = nil
        field_options[:required] = nil
      else
        field_options[:id] ||= input_dom_id
      end
      field_options[:class] ||= []
      field_options[:class] += ["#{input_dom_id} form-control multi-text-field"]
      field_options[:'aria-labelledby'] = label_id
      field_options.delete(:multiple)
      field_options.delete(:item_helper)
      field_options.merge!(options.slice(:include_blank))

      @rendered_first_element = true

      field_options
    end

    def build_field(value, index)
      render_options = select_options
      html_options = build_field_options(value)
      if options[:item_helper]
        (render_options, html_options) = options[:item_helper].call(value, index, render_options, html_options)
      end
      template.select_tag(attribute_name, template.options_for_select(render_options, value), html_options)
    end
end
