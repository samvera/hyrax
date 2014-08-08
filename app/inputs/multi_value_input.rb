class MultiValueInput < SimpleForm::Inputs::CollectionInput
  def input(wrapper_options)
    @rendered_first_element = false
    input_html_classes.unshift("string")
    #input_html_options[:type] ||= 'text'
    input_html_options[:name] ||= "#{object_name}[#{attribute_name}][]"
    markup = <<-HTML


        <ul class="listing">
    HTML

    collection.each_with_index do |value, i|
      unless value.to_s.strip.blank?
        markup << <<-HTML
          <li class="field-wrapper">
            #{build_text_field(value)}
          </li>
        HTML
      end
    end

    markup << <<-HTML
          <li class="field-wrapper">
            #{build_text_field('')}
          </li>
        </ul>

    HTML
  end

  private


  def build_text_field(value)
    options = input_html_options.dup

    options[:value] = value
    if @rendered_first_element
      options[:id] = nil
      options[:required] = nil
    else
      options[:id] ||= input_dom_id
    end
    options[:class] ||= []
    options[:class] += ["#{input_dom_id} form-control multi-text-field"]
    options[:'aria-labelledby'] = label_id
    @rendered_first_element = true
    if options.delete(:type) == 'textarea'.freeze
      @builder.text_area(attribute_name, options)
    else
      @builder.text_field(attribute_name, options)
    end
  end


  def label_id
    input_dom_id + '_label'
  end

  def input_dom_id
    input_html_options[:id] || "#{object_name}_#{attribute_name}"
  end

  def collection
    @collection ||= begin
      object.send(attribute_name)
    end
  end

  def multiple?; true; end
end
