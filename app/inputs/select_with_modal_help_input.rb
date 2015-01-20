class SelectWithModalHelpInput < MultiValueWithHelpInput
  def link_to_help
    template.link_to "##{attribute_name}Modal", id: "#{input_class}_help_modal", rel: 'button',
            data: { toggle: 'modal' }, :'aria-label' => aria_label do
      help_icon
    end
  end

  private
    def select_options
      @select_options ||= begin
        collection = options.delete(:collection) || self.class.boolean_collection
        collection.respond_to?(:call) ? collection.call : collection.to_a
      end
    end

    def build_field(value, index)
      html_options = input_html_options.dup

      if @rendered_first_element
        html_options[:id] = nil
        html_options[:required] = nil
      else
        html_options[:id] ||= input_dom_id
      end
      html_options[:class] ||= []
      html_options[:class] += ["#{input_dom_id} form-control multi-text-field"]
      html_options[:'aria-labelledby'] = label_id
      html_options.delete(:multiple)
      @rendered_first_element = true

      html_options.merge!(options.slice(:include_blank))
      template.select_tag(attribute_name, template.options_for_select(select_options, value), html_options)
    end

end
