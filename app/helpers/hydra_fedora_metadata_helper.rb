require "inline_editable_metadata_helper"
module HydraFedoraMetadataHelper
  
  def fedora_text_field(resource, datastream_name, field_key, opts={})
    field_name = field_name_for(field_key)
    field_values = get_values_from_datastream(resource, datastream_name, field_key, opts)
    
    if opts.fetch(:multiple, true)
      container_tag_type = :li
    else
      field_values = field_values.first
      container_tag_type = :span
    end
    
    body = ""
    
    field_values.each_with_index do |current_value, z|
      base_id = generate_base_id(field_name, current_value, field_values, opts)
      name = "asset[#{datastream_name}][#{base_id}]"
      
      body << "<#{container_tag_type.to_s} class=\"editable-container\" id=\"#{base_id}-container\">"
        body << "<span class=\"editable-text\" id=\"#{base_id}-text\">#{h(current_value)}</span>"
        body << "<input class=\"editable-edit\" id=\"#{base_id}\" name=\"#{name}\" value=\"#{h(current_value)}\"/>"
      body << "</#{container_tag_type}>"
    end
      
    result = field_selectors_for(datastream_name, field_key)
    
    if opts.fetch(:multiple, true)
      result << content_tag(:ol, body)
    else
      result << body
    end
    
    return result
  end
  
  def fedora_text_area(resource, datastream_name, field_key, opts={})
    fedora_textile_text_area(resource, datastream_name, field_key, opts)
  end
  
  # Textile textarea varies from the other methods in a few ways
  # Since we're using jeditable with this instead of fluid, we need to provide slightly different hooks for the javascript
  # * we are storing the datastream name in data-datastream-name so that we can construct a load url on the fly when initializing the textarea
  def fedora_textile_text_area(resource, datastream_name, field_key, opts={})
    field_name = field_name_for(field_key)
    field_values = get_values_from_datastream(resource, datastream_name, field_key, opts)
    
    if opts.fetch(:multiple, true)
      container_tag_type = :li
    else
      field_values = field_values.first
      container_tag_type = :span
    end
    body = ""

    field_values.each_with_index do |current_value, z|
      base_id = generate_base_id(field_name, current_value, field_values, opts)
      name = "asset[#{datastream_name}][#{base_id}]"
      processed_field_value = white_list( RedCloth.new(current_value, [:sanitize_html]).to_html)
      
      body << "<#{container_tag_type.to_s} class=\"field_value textile-container\" id=\"#{base_id}-container\" data-datastream-name=\"#{datastream_name}\">"
        # Not sure why there is we're not allowing the for the first textile to be deleted, but this was in the original helper.
        body << "<a href='#' class='destructive'><img src='/images/delete.png' alt='Delete'></a>" unless z == 0
        body << "<div class=\"textile-text\" id=\"#{base_id}-text\">#{processed_field_value}</div>"
        body << "<input class=\"textile-edit\" id=\"#{base_id}\" name=\"#{name}\" value=\"#{h(current_value)}\"/>"
      body << "</#{container_tag_type}>"
    end
    
    result = field_selectors_for(datastream_name, field_key)
    
    if opts.fetch(:multiple, true)
      result << content_tag(:ol, body)
    else
      result << body
    end
    
    return result
    
  end
  
  # Expects :choices option.  Option tags for the select are generated from the :choices option using Rails "options_for_select":http://apidock.com/rails/ActionView/Helpers/FormOptionsHelper/options_for_select helper
  # If no :choices option is provided, returns a regular fedora_text_field
  def fedora_select(resource, datastream_name, field_key, opts={})
    if opts[:choices].nil?
      result = fedora_text_field(resource, datastream_name, field_key, opts)
    else
      choices = opts[:choices]
      field_name = field_name_for(field_key)
      field_values = get_values_from_datastream(resource, datastream_name, field_key, opts)
      
      body = ""
      base_id = generate_base_id(field_name, field_values.first, field_values, opts.merge({:multiple=>false}))
      name = "asset[#{datastream_name}][#{base_id}]"

      body << "<select name=\"#{name}\" class=\"metadata-dd\">"
        body << options_for_select(choices, field_values)
      body << "</select>"
      
      result = field_selectors_for(datastream_name, field_key)
      
      result << body
    end
    return result
  end
  
  def fedora_date_select(resource, datastream_name, field_key, opts={})
  end
  
  def fedora_checkbox(resource, datastream_name, field_key, opts={})
  end
  
  def fedora_text_field_insert_link(resource, datastream_name, field_key, opts={})
  end
  
  def fedora_field_label()
  end
  
  def metadata_field_info(resource, datastream_name, field_key, opts={})
  end
  
  def field_selectors_for(datastream_name, field_key)
    result = ""
    if field_key.kind_of?(Array)
      h_name = ActiveFedora::NokogiriDatastream.accessor_hierarchical_name(*field_key)
      field_key.each do |pointer|
        if pointer.kind_of?(Hash)
          k = pointer.keys.first
          v = pointer.values.first
          # result << "<input type=\"hidden\", rel=\"#{h_name}\" name=\"field_selectors[#{datastream_name}][#{h_name}][][#{k}]\" value=\"#{v}\"/>"
          result << tag(:input, :type=>"hidden", :rel=>h_name, :name=>"field_selectors[#{datastream_name}][#{h_name}][][#{k}]", :value=>v)
        else
          result << tag(:input, :type=>"hidden", :rel=>h_name, :name=>"field_selectors[#{datastream_name}][#{h_name}][]", :value=>pointer.to_s)
        end
      end
    end
    return result
  end
  
  # hydra_form_for block helper 
  # allows you to construct an entire hydra form by passing a block into this method
  class HydraFormFor < BlockHelpers::Base

    def initialize(resource, opts={})
      @resource = resource
    end
    
    def fedora_label(datastream_name, field_key, opts={})
      helper.fedora_label(@resource, datastream_name, field_key, opts)
    end
    
    def fedora_text_field(datastream_name, field_key, opts={})
      helper.fedora_label(@resource, datastream_name, field_key, opts)
    end

    def fedora_text_area(datastream_name, field_key, opts={})
      helper.fedora_text_area(@resource, datastream_name, field_key, opts)
    end
    
    def fedora_select(datastream_name, field_key, opts={})
      helper.fedora_select(@resource, datastream_name, field_key, opts)
    end
    
    def fedora_checkbox(datastream_name, field_key, opts={})
      helper.fedora_checkbox(@resource, datastream_name, field_key, opts)
    end
    
    def fedora_text_field_insert_link(datastream_name, field_key, opts={})
      helper.fedora_text_field_insert_link(@resource, datastream_name, field_key, opts={})
    end
    
    def fedora_field_label(datastream_name, field_key, opts={})
      helper.fedora_field_label(@resource, datastream_name, field_key, opts)
    end

    def display(body)
      inner_html = content_tag :input, :type=>"hidden", :name=>"content_type", :value=>@resource.class.to_s.underscore
      inner_html = inner_html << body
      content_tag :form, inner_html
    end

  end
  
  # retrieve field values from datastream.
  # If :values is provided, skips accessing the datastream and returns the contents of :values instead.
  def get_values_from_datastream(resource, datastream_name, field_key, opts={})
    if opts.has_key?(:values)
      values = opts[:values]
      if values.nil? then values = [opts.fetch(:default, "")] end
      return values
    else
      return resource.get_values_from_datastream(datastream_name, field_key, opts.fetch(:default, ""))
    end
  end
  
  def field_name_for(field_key)
    if field_key.kind_of?(Array)
      return ActiveFedora::NokogiriDatastream.accessor_hierarchical_name(*field_key)
    else
      field_key.to_s
    end
  end
  
  def generate_base_id(field_name, current_value, values, opts)
    if opts.fetch(:multiple, true)
      return field_name+"_"+values.index(current_value).to_s
    else
      return field_name
    end
  end
  
end